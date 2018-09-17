require 'spec_helper'

describe Elasticsearch::Model::Searching::ClassMethods do

  before(:all) do
    class ::DummySearchingModel
      extend Elasticsearch::Model::Searching::ClassMethods

      def self.index_name;    'foo'; end
      def self.document_type; 'bar'; end
    end
  end

  after(:all) do
    Object.send(:remove_const, :DummySearchingModel) if defined?(DummySearchingModel)
  end

  it 'has the search method' do
    expect(DummySearchingModel).to respond_to(:search)
  end

  describe '#search' do

    let(:response) do
      double('search', execute!: { 'hits' => {'hits' => [ {'_id' => 2 }, {'_id' => 1 } ]} })
    end

    before do
      expect(Elasticsearch::Model::Searching::SearchRequest).to receive(:new).with(DummySearchingModel, 'foo', { default_operator: 'AND' }).and_return(response)
    end

    it 'creates a search object' do
      expect(DummySearchingModel.search('foo', default_operator: 'AND')).to be_a(Elasticsearch::Model::Response::Response)
    end
  end

  describe 'lazy execution' do

    let(:response) do
      double('search').tap do |r|
        expect(r).to receive(:execute!).never
      end
    end

    it 'does not execute the search until the results are accessed' do
      DummySearchingModel.search('foo')
    end
  end
end
