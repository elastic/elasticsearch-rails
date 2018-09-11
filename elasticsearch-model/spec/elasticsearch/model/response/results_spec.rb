require 'spec_helper'

describe Elasticsearch::Model::Response::Results do

  before(:all) do
    class OriginClass
      def self.index_name;    'foo'; end
      def self.document_type; 'bar'; end
    end
  end

  after(:all) do
    Object.send(:remove_const, :OriginClass) if defined?(OriginClass)
  end

  let(:response_document) do
    { 'hits' => { 'total' => 123, 'max_score' => 456, 'hits' => [{'foo' => 'bar'}] } }
  end

  let(:search) do
    Elasticsearch::Model::Searching::SearchRequest.new(OriginClass, '*').tap do |request|
      allow(request).to receive(:execute!).and_return(response_document)
    end
  end

  let(:response) do
    Elasticsearch::Model::Response::Response.new(OriginClass, search)
  end

  let(:results) do
    response.results
  end

  describe '#results' do

    it 'provides access to the results' do
      expect(results.results.size).to be(1)
      expect(results.results.first.foo).to eq('bar')
    end
  end

  describe 'Enumerable' do

    it 'deletebates enumerable methods to the results' do
      expect(results.empty?).to be(false)
      expect(results.first.foo).to eq('bar')
    end
  end

  describe '#raw_response' do

    it 'returns the raw response document' do
      expect(response.raw_response).to eq(response_document)
    end
  end
end
