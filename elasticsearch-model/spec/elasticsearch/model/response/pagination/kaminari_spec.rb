require 'spec_helper'

describe Elasticsearch::Model::Response::Response do

  before(:all) do
    class ModelClass
      include ::Kaminari::ConfigurationMethods
      def self.index_name;    'foo'; end
      def self.document_type; 'bar'; end
    end
  end

  after(:all) do
    Object.send(:remove_const, :ModelClass) if defined?(ModelClass)
  end

  let(:response_document) do
    { 'took' => '5', 'timed_out' => false, '_shards' => {'one' => 'OK'},
      'hits' => { 'total' => 100, 'hits' => (1..100).to_a.map { |i| { _id: i } } } }
  end

  let(:search) do
    Elasticsearch::Model::Searching::SearchRequest.new(model, '*')
  end

  let(:response) do
    allow(model).to receive(:client).and_return(client)
    Elasticsearch::Model::Response::Response.new(model, search, response_document).tap do |resp|
      allow(resp).to receive(:client).and_return(client)
    end

  end

  let(:client) do
    double('client')
  end

  shared_examples_for 'a search request that can be paginated' do

    describe '#page' do

      it 'does not set an initial from and size on the search definition' do
        expect(response.search.definition[:from]).to be(nil)
        expect(response.search.definition[:size]).to be(nil)
      end

      context 'when page is called once' do

        let(:search_request) do
          { index: index_field, from: 25, size: 25, q: '*', type: type_field}
        end

        before do
          expect(client).to receive(:search).with(search_request).and_return(response_document)
          response.page(2).to_a
        end

        it 'advances the from/size in the search request' do
          expect(response.search.definition[:from]).to be(25)
          expect(response.search.definition[:size]).to be(25)
        end
      end

      context 'when page is called more than once' do

        let(:search_request_one) do
          { index: index_field, from: 25, size: 25, q: '*', type: type_field}
        end

        let(:search_request_two) do
          { index: index_field, from: 75, size: 25, q: '*', type: type_field}
        end

        before do
          expect(client).to receive(:search).with(search_request_one).and_return(response_document)
          response.page(2).to_a
          expect(client).to receive(:search).with(search_request_two).and_return(response_document)
          response.page(4).to_a
        end

        it 'advances the from/size in the search request' do
          expect(response.search.definition[:from]).to be(75)
          expect(response.search.definition[:size]).to be(25)
        end
      end

      context 'when limit is also set' do

        before do
          response.records
          response.results
        end

        context 'when page is called before limit' do

          before do
            response.page(3).limit(35)
          end

          it 'sets the correct values' do
            expect(response.search.definition[:size]).to eq(35)
            expect(response.search.definition[:from]).to eq(70)
          end

          it 'resets the instance variables' do
            expect(response.instance_variable_get(:@response)).to be(nil)
            expect(response.instance_variable_get(:@records)).to be(nil)
            expect(response.instance_variable_get(:@results)).to be(nil)
          end
        end

        context 'when limit is called before page' do

          before do
            response.limit(35).page(3)
          end

          it 'sets the correct values' do
            expect(response.search.definition[:size]).to eq(35)
            expect(response.search.definition[:from]).to eq(70)
          end

          it 'resets the instance variables' do
            expect(response.instance_variable_get(:@response)).to be(nil)
            expect(response.instance_variable_get(:@records)).to be(nil)
            expect(response.instance_variable_get(:@results)).to be(nil)
          end
        end
      end
    end

    describe '#limit_value' do

      context 'when there is no default set' do

        it 'uses the limit value from the Kaminari configuration' do
          expect(response.limit_value).to eq(Kaminari.config.default_per_page)
        end
      end

      context 'when there is a limit in the search definition' do

        let(:search) do
          Elasticsearch::Model::Searching::SearchRequest.new(model, '*', size: 10)
        end

        it 'gets the limit from the search definition' do
          expect(response.limit_value).to eq(10)
        end
      end

      context 'when there is a limit in the search body' do

        let(:search) do
          Elasticsearch::Model::Searching::SearchRequest.new(model, { query: { match_all: {} }, size: 999 })
        end

        it 'does not use the limit' do
          expect(response.limit_value).to be(Kaminari.config.default_per_page)
        end
      end
    end

    describe '#offset_value' do

      context 'when there is no default set' do

        it 'uses an offset of 0' do
          expect(response.offset_value).to eq(0)
        end
      end

      context 'when there is an offset in the search definition' do

        let(:search) do
          Elasticsearch::Model::Searching::SearchRequest.new(model, '*', from: 50)
        end

        it 'gets the limit from the search definition' do
          expect(response.offset_value).to eq(50)
        end
      end

      context 'when there is an offset in the search body' do

        let(:search) do
          Elasticsearch::Model::Searching::SearchRequest.new(model, { query: { match_all: {} }, from: 333 })
        end

        it 'does not use the offset' do
          expect(response.offset_value).to be(0)
        end
      end
    end

    describe '#limit' do

      context 'when a limit is set' do

        before do
          response.records
          response.results
          response.limit(35)
        end

        it 'sets the limit on the search defintiion' do
          expect(response.search.definition[:size]).to eq(35)
        end

        it 'resets the instance variables' do
          expect(response.instance_variable_get(:@response)).to be(nil)
          expect(response.instance_variable_get(:@records)).to be(nil)
          expect(response.instance_variable_get(:@results)).to be(nil)
        end

        context 'when the limit is provided as a string' do

          before do
            response.limit('35')
          end

          it 'coerces the string to an integer' do
            expect(response.search.definition[:size]).to eq(35)
          end
        end

        context 'when the limit is an invalid type' do

          before do
            response.limit('asdf')
          end

          it 'does not apply the setting' do
            expect(response.search.definition[:size]).to eq(35)
          end
        end
      end
    end

    describe '#offset' do

      context 'when an offset is set' do

        before do
          response.records
          response.results
          response.offset(15)
        end

        it 'sets the limit on the search defintiion' do
          expect(response.search.definition[:from]).to eq(15)
        end

        it 'resets the instance variables' do
          expect(response.instance_variable_get(:@response)).to be(nil)
          expect(response.instance_variable_get(:@records)).to be(nil)
          expect(response.instance_variable_get(:@results)).to be(nil)
        end

        context 'when the offset is provided as a string' do

          before do
            response.offset('15')
          end

          it 'coerces the string to an integer' do
            expect(response.search.definition[:from]).to eq(15)
          end
        end

        context 'when the offset is an invalid type' do

          before do
            response.offset('asdf')
          end

          it 'does not apply the setting' do
            expect(response.search.definition[:from]).to eq(0)
          end
        end
      end
    end

    describe '#total' do

      before do
        allow(response.results).to receive(:total).and_return(100)
      end

      it 'returns the total number of hits' do
        expect(response.total_count).to eq(100)
      end
    end

    context 'results' do

      before do
        allow(search).to receive(:execute!).and_return(response_document)
      end

      describe '#current_page' do

        it 'returns the current page' do
          expect(response.results.current_page).to eq(1)
        end

        context 'when a particular page is accessed' do

          it 'returns the correct current page' do
            expect(response.page(5).results.current_page).to eq(5)
          end
        end
      end

      describe '#prev_page' do

        it 'returns the previous page' do
          expect(response.page(1).results.prev_page).to be(nil)
          expect(response.page(2).results.prev_page).to be(1)
          expect(response.page(3).results.prev_page).to be(2)
          expect(response.page(4).results.prev_page).to be(3)
        end
      end

      describe '#next_page' do

        it 'returns the previous page' do
          expect(response.page(1).results.next_page).to be(2)
          expect(response.page(2).results.next_page).to be(3)
          expect(response.page(3).results.next_page).to be(4)
          expect(response.page(4).results.next_page).to be(nil)
        end
      end
    end

    context 'records' do

      before do
        allow(search).to receive(:execute!).and_return(response_document)
      end

      describe '#current_page' do

        it 'returns the current page' do
          expect(response.records.current_page).to eq(1)
        end

        context 'when a particular page is accessed' do

          it 'returns the correct current page' do
            expect(response.page(5).records.current_page).to eq(5)
          end
        end
      end

      describe '#prev_page' do

        it 'returns the previous page' do
          expect(response.page(1).records.prev_page).to be(nil)
          expect(response.page(2).records.prev_page).to be(1)
          expect(response.page(3).records.prev_page).to be(2)
          expect(response.page(4).records.prev_page).to be(3)
        end
      end

      describe '#next_page' do

        it 'returns the previous page' do
          expect(response.page(1).records.next_page).to be(2)
          expect(response.page(2).records.next_page).to be(3)
          expect(response.page(3).records.next_page).to be(4)
          expect(response.page(4).records.next_page).to be(nil)
        end
      end
    end
  end

  context 'when the model is a single one' do

    let(:model) do
      ModelClass
    end

    let(:type_field) do
      'bar'
    end

    let(:index_field) do
      'foo'
    end

    it_behaves_like 'a search request that can be paginated'
  end

  context 'when the model is a multimodel' do

    let(:model) do
      Elasticsearch::Model::Multimodel.new(ModelClass)
    end

    let(:type_field) do
      ['bar']
    end

    let(:index_field) do
      ['foo']
    end

    it_behaves_like 'a search request that can be paginated'
  end
end