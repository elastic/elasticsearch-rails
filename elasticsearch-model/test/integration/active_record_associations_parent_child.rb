require 'test_helper'
require 'active_record'

class Question < ActiveRecord::Base
  include Elasticsearch::Model

  has_many :answers, dependent: :destroy

  index_name 'questions_and_answers'

  mapping do
    indexes :title
    indexes :text
    indexes :author
  end

  after_commit lambda { __elasticsearch__.index_document  },  on: :create
  after_commit lambda { __elasticsearch__.update_document },  on: :update
  after_commit lambda { __elasticsearch__.delete_document },  on: :destroy
end

class Answer < ActiveRecord::Base
  include Elasticsearch::Model

  belongs_to :question

  index_name 'questions_and_answers'

  mapping _parent: { type: 'question', required: true } do
    indexes :text
    indexes :author
  end

  after_commit lambda { __elasticsearch__.index_document(parent: question_id)  },  on: :create
  after_commit lambda { __elasticsearch__.update_document(parent: question_id) },  on: :update
  after_commit lambda { __elasticsearch__.delete_document(parent: question_id) },  on: :destroy
end

module ParentChildSearchable
  INDEX_NAME = 'questions_and_answers'

  def create_index!(options={})
    client = Question.__elasticsearch__.client
    client.indices.delete index: INDEX_NAME rescue nil if options[:force]

    settings = Question.settings.to_hash.merge Answer.settings.to_hash
    mappings = Question.mappings.to_hash.merge Answer.mappings.to_hash

    client.indices.create index: INDEX_NAME,
                          body: {
                            settings: settings.to_hash,
                            mappings: mappings.to_hash }
  end

  extend self
end

module Elasticsearch
  module Model
    class ActiveRecordAssociationsParentChildIntegrationTest < Elasticsearch::Test::IntegrationTestCase

      context "ActiveRecord associations with parent/child modelling" do
        setup do
          ActiveRecord::Schema.define(version: 1) do
            create_table :questions do |t|
              t.string     :title
              t.text       :text
              t.string     :author
              t.timestamps
            end
            create_table :answers do |t|
              t.text       :text
              t.string     :author
              t.references :question
              t.timestamps
            end and add_index(:answers, :question_id)
          end

          Question.delete_all
          ParentChildSearchable.create_index! force: true

          q_1 = Question.create! title: 'First Question',  author: 'John'
          q_2 = Question.create! title: 'Second Question', author: 'Jody'

          q_1.answers.create! text: 'Lorem Ipsum', author: 'Adam'
          q_1.answers.create! text: 'Dolor Sit',   author: 'Ryan'

          q_2.answers.create! text: 'Amet Et', author: 'John'

          Question.__elasticsearch__.refresh_index!
        end

        should "find questions by matching answers" do
          response = Question.search(
                       { query: {
                            has_child: {
                              type: 'answer',
                              query: {
                                match: {
                                  author: 'john'
                                }
                              }
                            }
                         }
                       })

          assert_equal 'Second Question', response.records.first.title
        end

        should "find answers for matching questions" do
          response = Answer.search(
                       { query: {
                            has_parent: {
                              parent_type: 'question',
                              query: {
                                match: {
                                  author: 'john'
                                }
                              }
                            }
                         }
                       })

          assert_same_elements ['Adam', 'Ryan'], response.records.map(&:author)
        end

        should "delete answers when the question is deleted" do
          Question.where(title: 'First Question').each(&:destroy)
          Question.__elasticsearch__.refresh_index!

          response = Answer.search query: { match_all: {} }

          assert_equal 1, response.results.total
        end
      end

    end
  end
end
