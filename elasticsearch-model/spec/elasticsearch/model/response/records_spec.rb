require 'spec_helper'

describe Elasticsearch::Model::Response::Records do

  before(:all) do
    class DummyCollection
      include Enumerable

      def each(&block); ['FOO'].each(&block); end
      def size;         ['FOO'].size;         end
      def empty?;       ['FOO'].empty?;       end
      def foo;          'BAR';                end
    end

    class DummyModel
      def self.index_name;    'foo'; end
      def self.document_type; 'bar'; end

      def self.find(*args)
        DummyCollection.new
      end
    end
  end

  after(:all) do
    remove_classes(DummyCollection, DummyModel)
  end

  let(:response_document) do
    { 'hits' => { 'total' => 123, 'max_score' => 456, 'hits' => [{'_id' => '1', 'foo' => 'bar'}] } }
  end

  let(:results) do
    Elasticsearch::Model::Response::Results.new(DummyModel, response_document)
  end

  let(:search) do
    Elasticsearch::Model::Searching::SearchRequest.new(DummyModel, '*').tap do |request|
      allow(request).to receive(:execute!).and_return(response_document)
    end
  end

  let(:response) do
    Elasticsearch::Model::Response::Response.new(DummyModel, search)
  end

  let(:records) do
    described_class.new(DummyModel, response)
  end

  context 'when the records are accessed' do

    it 'returns the records' do
      expect(records.records.size).to eq(1)
      expect(records.records.first).to eq('FOO')
    end

    it 'delegates methods to records' do
      expect(records.foo).to eq('BAR')
    end
  end

  describe '#each_with_hit' do

    it 'returns each record with its Elasticsearch hit' do
      records.each_with_hit do |record, hit|
        expect(record).to eq('FOO')
        expect(hit.foo).to eq('bar')
      end
    end
  end

  describe '#map_with_hit' do

    let(:value) do
      records.map_with_hit { |record, hit| "#{record}---#{hit.foo}" }
    end

    it 'returns each record with its Elasticsearch hit' do
      expect(value).to eq(['FOO---bar'])
    end
  end

  describe '#ids' do

    it 'returns the ids' do
      expect(records.ids).to eq(['1'])
    end
  end

  context 'when an adapter is used' do

    before do
      module DummyAdapter
        module RecordsMixin
          def records
            ['FOOBAR']
          end
        end

        def records_mixin
          RecordsMixin
        end; module_function :records_mixin
      end

      allow(Elasticsearch::Model::Adapter).to receive(:from_class).and_return(DummyAdapter)
    end

    after do
      Elasticsearch::Model::Adapter::Adapter.adapters.delete(DummyAdapter)
      Object.send(:remove_const, :DummyAdapter) if defined?(DummyAdapter)
    end

    it 'delegates the records method to the adapter' do
      expect(records.records).to eq(['FOOBAR'])
    end
  end
end
