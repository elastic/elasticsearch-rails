require 'spec_helper'

describe Elasticsearch::Persistence::Repository::Response::Results do

  before(:all) do
    class MyRepository
      include Elasticsearch::Persistence::Repository

      def deserialize(document)
        'Object'
      end
    end
  end

  let(:repository) do
    MyRepository.new
  end

  after(:all) do
    if defined?(MyRepository)
      Object.send(:remove_const, MyRepository.name)
    end
  end

  let(:response) do
    { "took" => 2,
      "timed_out" => false,
      "_shards" => {"total" => 5, "successful" => 5, "failed" => 0},
      "hits" =>
               { "total" => 2,
                 "max_score" => 0.19,
                 "hits" =>
                           [{"_index" => "my_index",
                             "_type" => "note",
                             "_id" => "1",
                             "_score" => 0.19,
                             "_source" => {"id" => 1, "title" => "Test 1"}},

                            {"_index" => "my_index",
                             "_type" => "note",
                             "_id" => "2",
                             "_score" => 0.19,
                             "_source" => {"id" => 2, "title" => "Test 2"}}
                            ]
               }
    }
  end

  let(:results) do
    described_class.new(repository, response)
  end

  describe '#repository' do

    it 'should return the repository' do
      expect(results.repository).to be(repository)
    end
  end

  describe '#response' do

    it 'returns the response' do
      expect(results.response).to eq(response)
    end

    it 'wraps the response in a HashWrapper' do
      expect(results.response._shards.total).to eq(5)
    end
  end

  describe '#total' do

    it 'returns the total' do
      expect(results.total).to eq(2)
    end
  end

  describe '#max_score' do

    it 'returns the max score' do
      expect(results.max_score).to eq(0.19)
    end
  end

  describe '#each' do

    it 'delegates the method to the results' do
      expect(results.size).to eq(2)
    end
  end

  describe '#each_with_hit' do

    it 'returns each deserialized object with the raw document' do
      expect(results.each_with_hit { |pair| pair[0] = 'Obj'}).to eq(['Obj', 'Obj'].zip(response['hits']['hits']))
    end
  end

  describe '#map_with_hit' do

    it 'returns the result of the block called on a pair of each raw document and the deserialized object' do
      expect(results.map_with_hit { |pair| pair[0] }).to eq(['Object', 'Object'])
    end
  end
end
