require 'spec_helper'

describe 'Elasticsearch::Model::Adapter::ActiveRecord MultiModel' do

  before(:all) do
    ActiveRecord::Schema.define do
      create_table Episode.table_name do |t|
        t.string :name
        t.datetime :created_at, :default => 'NOW()'
      end

      create_table Series.table_name do |t|
        t.string :name
        t.datetime :created_at, :default => 'NOW()'
      end
    end
  end

  before do
    models = [ Episode, Series ]
    clear_tables(models)
    models.each do |model|
      model.__elasticsearch__.create_index! force: true
      model.create name: "The #{model.name}"
      model.create name: "A great #{model.name}"
      model.create name: "The greatest #{model.name}"
      model.__elasticsearch__.refresh_index!
    end
  end

  after do
    clear_indices(Episode, Series)
    clear_tables(Episode, Series)
  end

  context 'when the search is across multimodels' do

    let(:search_result) do
      Elasticsearch::Model.search(%q<"The greatest Episode"^2 OR "The greatest Series">, [Series, Episode])
    end

    it 'executes the search across models' do
      expect(search_result.results.size).to eq(2)
      expect(search_result.records.size).to eq(2)
    end

    describe '#results' do

      it 'returns an instance of Elasticsearch::Model::Response::Result' do
        expect(search_result.results[0]).to be_a(Elasticsearch::Model::Response::Result)
        expect(search_result.results[1]).to be_a(Elasticsearch::Model::Response::Result)
      end

      it 'returns the correct model instance' do
        expect(search_result.results[0].name).to eq('The greatest Episode')
        expect(search_result.results[1].name).to eq('The greatest Series')
      end

      it 'provides access to the results' do
        expect(search_result.results[0].name).to eq('The greatest Episode')
        expect(search_result.results[0].name?).to be(true)
        expect(search_result.results[0].boo?).to be(false)

        expect(search_result.results[1].name).to eq('The greatest Series')
        expect(search_result.results[1].name?).to be(true)
        expect(search_result.results[1].boo?).to be(false)
      end
    end

    describe '#records' do

      it 'returns an instance of Elasticsearch::Model::Response::Result' do
        expect(search_result.records[0]).to be_a(Episode)
        expect(search_result.records[1]).to be_a(Series)
      end

      it 'returns the correct model instance' do
        expect(search_result.records[0].name).to eq('The greatest Episode')
        expect(search_result.records[1].name).to eq('The greatest Series')
      end

      context 'when the data store is changed' do

        before do
          Series.find_by_name("The greatest Series").delete
          Series.__elasticsearch__.refresh_index!
        end

        it 'only returns matching records' do
          expect(search_result.results.size).to eq(2)
          expect(search_result.records.size).to eq(1  )
          expect(search_result.records[0].name).to eq('The greatest Episode')
        end
      end
    end

    describe 'pagination' do

      let(:search_result) do
        Elasticsearch::Model.search('series OR episode', [Series, Episode])
      end

      it 'properly paginates the results' do
        expect(search_result.page(1).per(3).results.size).to eq(3)
        expect(search_result.page(2).per(3).results.size).to eq(3)
        expect(search_result.page(3).per(3).results.size).to eq(0)
      end
    end
  end
end
