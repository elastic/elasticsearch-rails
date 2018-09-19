require 'spec_helper'

describe Elasticsearch::Model::Response::Response do

  before(:all) do
    class OriginClass
      def self.index_name;    'foo'; end
      def self.document_type; 'bar'; end
    end
  end

  after(:all) do
    remove_classes(OriginClass)
  end

  let(:response_document) do
    { 'took' => '5', 'timed_out' => false, '_shards' => {'one' => 'OK'}, 'hits' => { 'hits' => [] },
      'aggregations' => {'foo' => {'bar' => 10}},
      'suggest' => {'my_suggest' => [ { 'text' => 'foo', 'options' => [ { 'text' => 'Foo', 'score' => 2.0 },
                                                                        { 'text' => 'Bar', 'score' => 1.0 } ] } ]}}

  end

  let(:search) do
    Elasticsearch::Model::Searching::SearchRequest.new(OriginClass, '*').tap do |request|
      allow(request).to receive(:execute!).and_return(response_document)
    end
  end

  let(:response) do
    Elasticsearch::Model::Response::Response.new(OriginClass, search)
  end

  it 'performs the Elasticsearch request lazily' do
    expect(search).not_to receive(:execute!)
    response
  end

  describe '#klass' do

    it 'returns the class' do
      expect(response.klass).to be(OriginClass)
    end
  end

  describe '#search' do

    it 'returns the search object' do
      expect(response.search).to eq(search)
    end
  end

  describe '#took' do

    it 'returns the took field' do
      expect(response.took).to eq('5')
    end
  end

  describe '#timed_out' do

    it 'returns the timed_out field' do
      expect(response.timed_out).to eq(false)
    end
  end

  describe '#shards' do

    it 'returns a Hashie::Mash' do
      expect(response.shards.one).to eq('OK')
    end
  end

  describe '#response' do

    it 'returns the response document' do
      expect(response.response).to eq(response_document)
    end
  end

  describe '#results' do

    it 'provides access to the results' do
      expect(response.results).to be_a(Elasticsearch::Model::Response::Results)
      expect(response.size).to be(0)
    end
  end

  describe '#records' do

    it 'provides access to the records' do
      expect(response.records).to be_a(Elasticsearch::Model::Response::Records)
      expect(response.size).to be(0)
    end
  end

  describe 'enumerable methods' do

    it 'delegates the methods to the results' do
      expect(response.empty?).to be(true)
    end
  end

  describe 'aggregations' do

    it 'provides access to the aggregations' do
      expect(response.aggregations).to be_a(Hashie::Mash)
      expect(response.aggregations.foo.bar).to eq(10)
    end
  end

  describe 'suggestions' do

    it 'provides access to the suggestions' do
      expect(response.suggestions).to be_a(Hashie::Mash)
      expect(response.suggestions.my_suggest.first.options.first.text).to eq('Foo')
      expect(response.suggestions.terms).to eq([ 'Foo', 'Bar' ])
    end

    context 'when there are no suggestions' do

      let(:response_document) do
        { }
      end

      it 'returns an empty list' do
        expect(response.suggestions.terms).to eq([ ])
      end
    end
  end
end
