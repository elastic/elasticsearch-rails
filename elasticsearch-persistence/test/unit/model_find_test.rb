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

      attribute :title, String
      attribute :count, Integer, default: 0
      attribute :created_at, DateTime, default: lambda { |o,a| Time.now.utc }
      attribute :updated_at, DateTime, default: lambda { |o,a| Time.now.utc }
    end

    setup do
      @gateway = stub(client: stub(), index_name: 'foo', document_type: 'bar')
      DummyFindModel.stubs(:gateway).returns(@gateway)

      DummyFindModel.stubs(:index_name).returns('foo')
      DummyFindModel.stubs(:document_type).returns('bar')

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
      DummyFindModel
        .stubs(:search)
        .with({ query: { match_all: {} }, size: 10_000 }, {})
        .returns(@response)

      DummyFindModel.all
    end

    should "pass options when finding all records" do
      DummyFindModel
        .expects(:search)
        .with({ query: { match: { title: 'test' } }, size: 10_000 }, { routing: 'abc123' })
        .returns(@response)

      DummyFindModel.all( { query: { match: { title: 'test' } } }, { routing: 'abc123' } )
    end

    context "finding via scan/scroll" do
      setup do
        @gateway
        .expects(:deserialize)
        .with('_source' => {'foo' => 'bar'})
        .returns('_source' => {'foo' => 'bar'})

        @gateway.client
          .expects(:search)
          .with do |arguments|
            assert_equal 'scan', arguments[:search_type]
            assert_equal 'foo',  arguments[:index]
            assert_equal 'bar',  arguments[:type]
            true
          end
          .returns(MultiJson.load('{"_scroll_id":"abc123==", "hits":{"hits":[]}}'))

        @gateway.client
          .expects(:scroll)
          .twice
          .returns(MultiJson.load('{"_scroll_id":"abc456==", "hits":{"hits":[{"_source":{"foo":"bar"}}]}}'))
          .then
          .returns(MultiJson.load('{"_scroll_id":"abc789==", "hits":{"hits":[]}}'))
      end

      should "find all records in batches" do
        @doc = nil
        result = DummyFindModel.find_in_batches { |batch| @doc = batch.first['_source']['foo'] }

        assert_equal 'abc789==', result
        assert_equal 'bar',      @doc
      end

      should "return an Enumerator for find in batches" do
        @doc = nil
        assert_nothing_raised do
          e = DummyFindModel.find_in_batches
          assert_instance_of Enumerator, e

          e.each { |batch| @doc = batch.first['_source']['foo'] }
          assert_equal 'bar',      @doc
        end
      end

      should "find each" do
        @doc = nil
        result = DummyFindModel.find_each { |doc| @doc = doc['_source']['foo'] }

        assert_equal 'abc789==', result
        assert_equal 'bar',      @doc
      end

      should "return an Enumerator for find each" do
        @doc = nil
        assert_nothing_raised do
          e = DummyFindModel.find_each
          assert_instance_of Enumerator, e

          e.each { |doc| @doc = doc['_source']['foo'] }
          assert_equal 'bar',      @doc
        end
      end
    end

  end
end
