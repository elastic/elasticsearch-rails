require 'test_helper'

require 'active_model'
require 'virtus'

require 'elasticsearch/persistence/model/errors'
require 'elasticsearch/persistence/model/find'

class Elasticsearch::Persistence::ModelFindTest < Test::Unit::TestCase
  context "The model find module," do

    class DummyFindModel
      include ActiveModel::Naming
      include ActiveModel::Conversion
      include ActiveModel::Serialization
      include ActiveModel::Serializers::JSON
      include ActiveModel::Validations

      include Virtus.model

      extend  Elasticsearch::Persistence::Model::Find::ClassMethods

      extend  ActiveModel::Callbacks
      define_model_callbacks :create, :save, :update, :destroy
      define_model_callbacks :find, :touch, only: :after

      attribute :id,    String, writer: :private
      attribute :title, String
      attribute :count, Integer, default: 0
      attribute :created_at, DateTime, default: lambda { |o,a| Time.now.utc }
      attribute :updated_at, DateTime, default: lambda { |o,a| Time.now.utc }

      def set_id(id); self.id = id; end
    end

    setup do
      @gateway         = stub
      DummyFindModel.stubs(:gateway).returns(@gateway)

      @response = MultiJson.load <<-JSON
        {
          "took": 14,
          "timed_out": false,
          "_shards": {
            "total": 5,
            "successful": 5,
            "failed": 0
          },
          "hits": {
            "total": 1,
            "max_score": 1.0,
            "hits": [
              {
                "_index": "dummy",
                "_type": "dummy",
                "_id": "abc123",
                "_score": 1.0,
                "_source": {
                  "name": "TEST"
                }
              }
            ]
          }
        }
      JSON
    end

    should "find all records" do
      @gateway
        .expects(:search)
        .with({ query: { match_all: {} }, size: 10_000 })
        .returns(@response)

      DummyFindModel.all
    end

    should "pass options when finding all records" do
      @gateway
        .expects(:search)
        .with({ query: { match: { title: 'test' } }, size: 10_000, routing: 'abc123' })
        .returns(@response)

      DummyFindModel.all( { query: { match: { title: 'test' } }, routing: 'abc123' } )
    end

  end
end
