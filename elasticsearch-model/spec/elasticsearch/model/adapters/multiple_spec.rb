require 'spec_helper'

describe Elasticsearch::Model::Adapter::Multiple do

  before(:all) do
    class DummyOne
      include Elasticsearch::Model

      index_name 'dummy'
      document_type 'dummy_one'

      def self.find(ids)
        ids.map { |id| new(id) }
      end

      attr_reader :id

      def initialize(id)
        @id = id.to_i
      end
    end

    module Namespace
      class DummyTwo
        include Elasticsearch::Model

        index_name 'dummy'
        document_type 'dummy_two'

        def self.find(ids)
          ids.map { |id| new(id) }
        end

        attr_reader :id

        def initialize(id)
          @id = id.to_i
        end
      end
    end

    class DummyTwo
      include Elasticsearch::Model

      index_name 'other_index'
      document_type 'dummy_two'

      def self.find(ids)
        ids.map { |id| new(id) }
      end

      attr_reader :id

      def initialize(id)
        @id = id.to_i
      end
    end
  end

  after(:all) do
    Elasticsearch::Model::Adapter::Adapter.adapters.delete(DummyOne)
    Elasticsearch::Model::Adapter::Adapter.adapters.delete(Namespace::DummyTwo)
    Elasticsearch::Model::Adapter::Adapter.adapters.delete(DummyTwo)
    Object.send(:remove_const, :DummyOne) if defined?(DummyOne)
    Object.send(:remove_const, :Namespace) if defined?(Namespace::DummyTwo)
    Object.send(:remove_const, :DummyTwo) if defined?(DummyTwo)
  end

  let(:hits) do
    [
      {
        _index: 'dummy',
        _type: 'dummy_two',
        _id: '2'
      },
      {
        _index: 'dummy',
        _type: 'dummy_one',
        _id: '2'
      },
      {
        _index: 'other_index',
        _type: 'dummy_two',
        _id: '1'
      },
      {
        _index: 'dummy',
        _type: 'dummy_two',
        _id: '1'
      },
      {
        _index: 'dummy',
        _type: 'dummy_one',
        _id: '3'
      }
    ]
  end

  let(:response) do
    double('response', response: { 'hits' => { 'hits' => hits } })
  end

  let(:multimodel) do
    Elasticsearch::Model::Multimodel.new(DummyOne, DummyTwo, Namespace::DummyTwo)
  end

  describe '#records' do

    before do
      multimodel.class.send :include, Elasticsearch::Model::Adapter::Multiple::Records
      expect(multimodel).to receive(:response).at_least(:once).and_return(response)
    end

    it 'instantiates the correct types of instances' do
      expect(multimodel.records[0]).to be_a(Namespace::DummyTwo)
      expect(multimodel.records[1]).to be_a(DummyOne)
      expect(multimodel.records[2]).to be_a(DummyTwo)
      expect(multimodel.records[3]).to be_a(Namespace::DummyTwo)
      expect(multimodel.records[4]).to be_a(DummyOne)
    end

    it 'returns the results in the correct order' do
      expect(multimodel.records.map(&:id)).to eq([2, 2, 1, 1, 3])
    end
  end
end
