require 'spec_helper'

describe 'Elasticsearch::Model::Adapter::ActiveRecord Parent-Child' do

  before(:all) do
    ActiveRecord::Schema.define(version: 1) do
      create_table :questions do |t|
        t.string     :title
        t.text       :text
        t.string     :author
        t.timestamps null: false
      end

      create_table :answers do |t|
        t.text       :text
        t.string     :author
        t.references :question
        t.timestamps null: false
      end

      add_index(:answers, :question_id) unless index_exists?(:answers, :question_id)

      clear_tables(Question)
      ParentChildSearchable.create_index!(force: true)

      q_1 = Question.create!(title: 'First Question',  author: 'John')
      q_2 = Question.create!(title: 'Second Question', author: 'Jody')

      q_1.answers.create!(text: 'Lorem Ipsum', author: 'Adam')
      q_1.answers.create!(text: 'Dolor Sit',   author: 'Ryan')

      q_2.answers.create!(text: 'Amet Et', author: 'John')

      Question.__elasticsearch__.refresh_index!
    end
  end

  describe 'has_child search' do

    let(:search_result) do
      Question.search(query: { has_child: { type: 'answer', query: { match: { author: 'john' } } } })
    end

    it 'finds parents by matching on child search criteria' do
      expect(search_result.records.first.title).to eq('Second Question')
    end
  end

  describe 'hash_parent search' do

    let(:search_result) do
      Answer.search(query: { has_parent: { parent_type: 'question', query: { match: { author: 'john' } } } })
    end

    it 'finds children by matching in parent criteria' do
      expect(search_result.records.map(&:author)).to match(['Adam', 'Ryan'])
    end
  end

  context 'when a parent is deleted' do

    before do
      Question.where(title: 'First Question').each(&:destroy)
      Question.__elasticsearch__.refresh_index!
    end

    let(:search_result) do
      Answer.search(query: { has_parent: { parent_type: 'question', query: { match_all: {} } } })
    end

    it 'deletes the children' do
      expect(search_result.results.total).to eq(1)
    end
  end
end
