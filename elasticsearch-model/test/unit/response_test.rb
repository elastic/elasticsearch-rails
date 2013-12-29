require 'test_helper'

class Elasticsearch::Model::ResponseTest < Test::Unit::TestCase
  context "Response" do
    class OriginClass
      def self.index_name;    'foo'; end
      def self.document_type; 'bar'; end
    end

    RESPONSE = { 'took' => '5', 'timed_out' => false, '_shards' => {'one' => 'OK'}, 'hits' => { 'hits' => [] } }

    setup do
      @search  = Elasticsearch::Model::Searching::SearchRequest.new OriginClass, '*'
      @search.stubs(:execute!).returns(RESPONSE)
    end

    should "access klass, response, took, timed_out, shards" do
      response = Elasticsearch::Model::Response::Response.new OriginClass, @search

      assert_equal OriginClass, response.klass
      assert_equal @search,     response.search
      assert_equal RESPONSE,    response.response
      assert_equal '5',         response.took
      assert_equal false,       response.timed_out
      assert_equal 'OK',        response.shards.one
    end

    should "load and access the results" do
      @search.expects(:execute!).returns(RESPONSE)

      response = Elasticsearch::Model::Response::Response.new OriginClass, @search
      assert_instance_of Elasticsearch::Model::Response::Results, response.results
      assert_equal 0, response.size
    end

    should "load and access the records" do
      @search.expects(:execute!).returns(RESPONSE)

      response = Elasticsearch::Model::Response::Response.new OriginClass, @search
      assert_instance_of Elasticsearch::Model::Response::Records, response.records
      assert_equal 0, response.size
    end

    should "delegate Enumerable methods to results" do
      @search.expects(:execute!).returns(RESPONSE)

      response = Elasticsearch::Model::Response::Response.new OriginClass, @search
      assert response.empty?
    end

    should "be initialized lazily" do
      @search.expects(:execute!).never

      Elasticsearch::Model::Response::Response.new OriginClass, @search
    end
  end
end
