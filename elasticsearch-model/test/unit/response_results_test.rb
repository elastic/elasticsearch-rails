require 'test_helper'

class Elasticsearch::Model::ResultsTest < Test::Unit::TestCase
  context "Response results" do
    class OriginClass
      def self.index_name;    'foo'; end
      def self.document_type; 'bar'; end
    end

    RESPONSE = { 'hits' => { 'total' => 123, 'max_score' => 456, 'hits' => [{'foo' => 'bar'}] } }

    setup do
      @search   = Elasticsearch::Model::Searching::SearchRequest.new OriginClass, '*'
      @response = Elasticsearch::Model::Response::Response.new OriginClass, @search
      @results  = Elasticsearch::Model::Response::Results.new  OriginClass, @response
      @search.stubs(:execute!).returns(RESPONSE)
    end

    should "access the results" do
      assert_respond_to @results, :results
      assert_equal 1, @results.results.size
      assert_equal 'bar', @results.results.first.foo
    end

    should "delegate Enumerable methods to results" do
      assert ! @results.empty?
      assert_equal 'bar', @results.first.foo
    end

    should "provide access to the raw response" do
      assert_equal RESPONSE, @response.raw_response
    end
  end
end
