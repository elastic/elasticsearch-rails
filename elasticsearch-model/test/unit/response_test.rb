require 'test_helper'

class Elasticsearch::Model::ResponseTest < Test::Unit::TestCase
  context "Response" do
    class OriginClass
      def self.index_name;    'foo'; end
      def self.document_type; 'bar'; end
    end

    RESPONSE = { 'took' => '5', 'timed_out' => false, '_shards' => {'one' => 'OK'}, 'hits' => { 'hits' => [] },
                 'aggregations' => {'foo' => {'bar' => 10}},
                 'suggest' => {'my_suggest' => [ { 'text' => 'foo', 'options' => [ { 'text' => 'Foo', 'score' => 2.0 }, { 'text' => 'Bar', 'score' => 1.0 } ] } ]}}

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

    should "wrap the raw Hash response in a HashWrapper" do
      @search  = Elasticsearch::Model::Searching::SearchRequest.new OriginClass, '*'
      @search.stubs(:execute!).returns({'hits' => { 'hits' => [] }, 'aggregations' => { 'dates' => 'FOO' }})

      response = Elasticsearch::Model::Response::Response.new OriginClass, @search

      assert_respond_to response.response, :aggregations
      assert_equal 'FOO', response.response.aggregations.dates
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

    should "access the aggregations" do
      @search.expects(:execute!).returns(RESPONSE)

      response = Elasticsearch::Model::Response::Response.new OriginClass, @search
      assert_respond_to response, :aggregations
      assert_kind_of Hashie::Mash, response.aggregations.foo
      assert_equal 10, response.aggregations.foo.bar
    end

    should "access the suggest" do
      @search.expects(:execute!).returns(RESPONSE)

      response = Elasticsearch::Model::Response::Response.new OriginClass, @search

      assert_respond_to response, :suggestions
      assert_kind_of Hashie::Mash, response.suggestions
      assert_equal 'Foo', response.suggestions.my_suggest.first.options.first.text
    end

    should "return array of terms from the suggestions" do
      @search.expects(:execute!).returns(RESPONSE)
      response = Elasticsearch::Model::Response::Response.new OriginClass, @search

      assert_not_empty response.suggestions
      assert_equal [ 'Foo', 'Bar' ], response.suggestions.terms
    end

    should "return empty array as suggest terms when there are no suggestions" do
      @search.expects(:execute!).returns({})
      response = Elasticsearch::Model::Response::Response.new OriginClass, @search

      assert_empty response.suggestions
      assert_equal [], response.suggestions.terms
    end
  end
end
