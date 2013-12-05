require 'test_helper'

class Elasticsearch::Model::ResultsTest < Test::Unit::TestCase
  context "Response results" do
    RESPONSE = { 'hits' => { 'total' => 123, 'max_score' => 456, 'hits' => [{'foo' => 'bar'}] } }

    setup do
      class DummyClass; end
      @results = Elasticsearch::Model::Response::Results.new DummyClass, RESPONSE
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

  end
end
