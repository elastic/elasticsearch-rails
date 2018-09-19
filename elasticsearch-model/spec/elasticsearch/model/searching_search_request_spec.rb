require 'spec_helper'

describe Elasticsearch::Model::Serializing do

  before(:all) do
    class ::DummySearchingModel
      extend Elasticsearch::Model::Searching::ClassMethods
      def self.index_name;    'foo'; end
      def self.document_type; 'bar'; end
    end
  end

  after(:all) do
    remove_classes(DummySearchingModel)
  end

  before do
    allow(DummySearchingModel).to receive(:client).and_return(client)
  end

  let(:client) do
    double('client')
  end

  describe '#initialize' do

    context 'when the search definition is a simple query' do

      before do
        expect(client).to receive(:search).with(index: 'foo', type: 'bar', q: 'foo').and_return({})
      end

      let(:search) do
        Elasticsearch::Model::Searching::SearchRequest.new(DummySearchingModel, 'foo')
      end

      it 'passes the query to the client' do
        expect(search.execute!).to eq({})
      end
    end

    context 'when the search definition is a hash' do

      before do
        expect(client).to receive(:search).with(index: 'foo', type: 'bar', body: { foo: 'bar' }).and_return({})
      end

      let(:search) do
        Elasticsearch::Model::Searching::SearchRequest.new(DummySearchingModel, foo: 'bar')
      end

      it 'passes the hash to the client' do
        expect(search.execute!).to eq({})
      end
    end

    context 'when the search definition is a json string' do

      before do
        expect(client).to receive(:search).with(index: 'foo', type: 'bar', body: '{"foo":"bar"}').and_return({})
      end

      let(:search) do
        Elasticsearch::Model::Searching::SearchRequest.new(DummySearchingModel, '{"foo":"bar"}')
      end

      it 'passes the json string to the client' do
        expect(search.execute!).to eq({})
      end
    end

    context 'when the search definition is a custom object' do

      before(:all) do
        class MySpecialQueryBuilder
          def to_hash; {foo: 'bar'}; end
        end
      end

      after(:all) do
        Object.send(:remove_const, :MySpecialQueryBuilder) if defined?(MySpecialQueryBuilder)
      end

      before do
        expect(client).to receive(:search).with(index: 'foo', type: 'bar', body: {foo: 'bar'}).and_return({})
      end

      let(:search) do
        Elasticsearch::Model::Searching::SearchRequest.new(DummySearchingModel, MySpecialQueryBuilder.new)
      end

      it 'passes the query builder to the client and calls #to_hash on it' do
        expect(search.execute!).to eq({})
      end
    end

    context 'when extra options are specified' do

      before do
        expect(client).to receive(:search).with(index: 'foo', type: 'bar', q: 'foo', size: 15).and_return({})
      end

      let(:search) do
        Elasticsearch::Model::Searching::SearchRequest.new(DummySearchingModel, 'foo', size: 15)
      end

      it 'passes the extra options to the client as part of the request' do
        expect(search.execute!).to eq({})
      end
    end
  end
end
