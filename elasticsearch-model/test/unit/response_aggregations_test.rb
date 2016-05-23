require 'test_helper'

class Elasticsearch::Model::ResponseAggregationsTest < Test::Unit::TestCase
  context "Response aggregations" do
    class OriginClass
      def self.index_name;    'foo'; end
      def self.document_type; 'bar'; end
    end

    RESPONSE = {
      'aggregations' => {
        'foo' => {'bar' => 10 },
        'price' => { 'doc_count' => 123,
                     'min' => { 'value' => 1.0},
                     'max' => { 'value' => 99 }
                   }
      }
    }

    setup do
      @search  = Elasticsearch::Model::Searching::SearchRequest.new OriginClass, '*'
      @search.stubs(:execute!).returns(RESPONSE)
    end

    should "access the aggregations" do
      @search.expects(:execute!).returns(RESPONSE)

      response = Elasticsearch::Model::Response::Response.new OriginClass, @search
      assert_respond_to response, :aggregations
      assert_kind_of Elasticsearch::Model::Response::Aggregations, response.aggregations
      assert_kind_of Hashie::Mash, response.aggregations.foo
      assert_equal 10, response.aggregations.foo.bar
    end

    should "properly return min and max values" do
      @search.expects(:execute!).returns(RESPONSE)

      response = Elasticsearch::Model::Response::Response.new OriginClass, @search

      assert_equal 123, response.aggregations.price.doc_count
      assert_equal 1,   response.aggregations.price.min.value
      assert_equal 99,  response.aggregations.price.max.value
    end

  end
end
