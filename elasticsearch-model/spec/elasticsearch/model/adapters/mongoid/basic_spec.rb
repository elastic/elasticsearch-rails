require 'spec_helper'

describe Elasticsearch::Model::Adapter::Mongoid, if: test_mongoid? do

  before(:all) do
    connect_mongoid('mongoid_test')
    Elasticsearch::Model::Adapter.register \
              Elasticsearch::Model::Adapter::Mongoid,
              lambda { |klass| !!defined?(::Mongoid::Document) && klass.respond_to?(:ancestors) && klass.ancestors.include?(::Mongoid::Document) }

    MongoidArticle.__elasticsearch__.create_index! force: true

    MongoidArticle.delete_all

    MongoidArticle.__elasticsearch__.refresh_index!
    MongoidArticle.__elasticsearch__.client.cluster.health wait_for_status: 'yellow'
  end

  after do
    clear_indices(MongoidArticle)
    clear_tables(MongoidArticle)
  end

  describe 'searching' do

    before do
      MongoidArticle.create! title: 'Test'
      MongoidArticle.create! title: 'Testing Coding'
      MongoidArticle.create! title: 'Coding'
      MongoidArticle.__elasticsearch__.refresh_index!
    end

    let(:search_result) do
      MongoidArticle.search('title:test')
    end

    it 'find the documents successfully' do
      expect(search_result.results.size).to eq(2)
      expect(search_result.records.size).to eq(2)
    end

    describe '#results' do

      it 'returns a Elasticsearch::Model::Response::Result' do
        expect(search_result.results.first).to be_a(Elasticsearch::Model::Response::Result)
      end

      it 'retrieves the document from Elasticsearch' do
        expect(search_result.results.first.title).to eq('Test')
      end

      it 'retrieves all results' do
        expect(search_result.results.collect(&:title)).to match(['Test', 'Testing Coding'])
      end
    end

    describe '#records' do

      it 'returns an instance of the model' do
        expect(search_result.records.first).to be_a(MongoidArticle)
      end

      it 'retrieves the document from Elasticsearch' do
        expect(search_result.records.first.title).to eq('Test')
      end

      it 'iterates over the records' do
        expect(search_result.records.first.title).to eq('Test')
      end

      it 'retrieves all records' do
        expect(search_result.records.collect(&:title)).to match(['Test', 'Testing Coding'])
      end

      describe '#each_with_hit' do

        it 'yields each hit with the model object' do
          search_result.records.each_with_hit do |r, h|
            expect(h._source).not_to be_nil
            expect(h._source.title).not_to be_nil
          end
        end

        it 'preserves the search order' do
          search_result.records.each_with_hit do |r, h|
            expect(r.id.to_s).to eq(h._id)
          end
        end
      end

      describe '#map_with_hit' do

        it 'yields each hit with the model object' do
          search_result.records.map_with_hit do |r, h|
            expect(h._source).not_to be_nil
            expect(h._source.title).not_to be_nil
          end
        end

        it 'preserves the search order' do
          search_result.records.map_with_hit do |r, h|
            expect(r.id.to_s).to eq(h._id)
          end
        end
      end
    end
  end

  describe '#destroy' do

    let(:article) do
      MongoidArticle.create!(title: 'Test')
    end

    before do
      article
      MongoidArticle.create!(title: 'Coding')
      article.destroy
      MongoidArticle.__elasticsearch__.refresh_index!
    end

    it 'removes documents from the index' do
      expect(MongoidArticle.search('title:test').results.total).to eq(0)
      expect(MongoidArticle.search('title:code').results.total).to eq(1)
    end
  end

  describe 'updates to the document' do

    let(:article) do
      MongoidArticle.create!(title: 'Test')
    end

    before do
      article.title = 'Writing'
      article.save
      MongoidArticle.__elasticsearch__.refresh_index!
    end

    it 'indexes updates' do
      expect(MongoidArticle.search('title:write').results.total).to eq(1)
      expect(MongoidArticle.search('title:test').results.total).to eq(0)
    end
  end

  describe 'DSL search' do

    before do
      MongoidArticle.create! title: 'Test'
      MongoidArticle.create! title: 'Testing Coding'
      MongoidArticle.create! title: 'Coding'
      MongoidArticle.__elasticsearch__.refresh_index!
    end

    let(:search_result) do
      MongoidArticle.search(query: { match: { title: { query: 'test' } } })
    end

    it 'finds the matching documents' do
      expect(search_result.results.size).to eq(2)
      expect(search_result.records.size).to eq(2)
    end
  end

  describe 'paging a collection' do

    before do
      MongoidArticle.create! title: 'Test'
      MongoidArticle.create! title: 'Testing Coding'
      MongoidArticle.create! title: 'Coding'
      MongoidArticle.__elasticsearch__.refresh_index!
    end

    let(:search_result) do
      MongoidArticle.search(query: { match: { title: { query: 'test' } } },
                            size: 2,
                            from: 1)
    end

    it 'applies the size and from parameters' do
      expect(search_result.results.size).to eq(1)
      expect(search_result.results.first.title).to eq('Testing Coding')
      expect(search_result.records.size).to eq(1)
      expect(search_result.records.first.title).to eq('Testing Coding')
    end
  end

  describe 'importing' do

    before do
      97.times { |i| MongoidArticle.create! title: "Test #{i}" }
      MongoidArticle.__elasticsearch__.create_index! force: true
      MongoidArticle.__elasticsearch__.client.cluster.health wait_for_status: 'yellow'
    end

    context 'when there is no default scope' do

      let!(:batch_count) do
        batches = 0
        errors  = MongoidArticle.import(batch_size: 10) do |response|
          batches += 1
        end
        MongoidArticle.__elasticsearch__.refresh_index!
        batches
      end

      it 'imports all the documents' do
        expect(MongoidArticle.search('*').results.total).to eq(97)
      end

      it 'uses the specified batch size' do
        expect(batch_count).to eq(10)
      end
    end

    context 'when there is a default scope' do

      around(:all) do |example|
        10.times { |i| MongoidArticle.create! title: 'Test', views: "#{i}" }
        MongoidArticle.default_scope -> { MongoidArticle.gt(views: 3) }
        example.run
        MongoidArticle.default_scoping = nil
      end

      before do
        MongoidArticle.__elasticsearch__.import
        MongoidArticle.__elasticsearch__.refresh_index!
      end

      it 'uses the default scope' do
        expect(MongoidArticle.search('*').results.total).to eq(6)
      end
    end

    context 'when there is a default scope and a query specified' do

      around(:all) do |example|
        10.times { |i| MongoidArticle.create! title: 'Test', views: "#{i}" }
        MongoidArticle.default_scope -> { MongoidArticle.gt(views: 3) }
        example.run
        MongoidArticle.default_scoping = nil
      end

      before do
        MongoidArticle.import(query: -> { lte(views: 4) })
        MongoidArticle.__elasticsearch__.refresh_index!
      end

      it 'combines the query and the default scope' do
        expect(MongoidArticle.search('*').results.total).to eq(1)
      end
    end

    context 'when the batch is empty' do

      before do
        MongoidArticle.delete_all
        MongoidArticle.import
        MongoidArticle.__elasticsearch__.refresh_index!
      end

      it 'does not make any requests to create documents' do
        expect(MongoidArticle.search('*').results.total).to eq(0)
      end
    end
  end
end
