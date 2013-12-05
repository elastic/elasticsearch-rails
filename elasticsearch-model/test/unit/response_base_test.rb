require 'test_helper'

class Elasticsearch::Model::ResultTest < Test::Unit::TestCase
  context "Response base module" do
    class OriginClass; end

    class DummyBaseClass
      include Elasticsearch::Model::Response::Base
    end

    RESPONSE = { 'hits' => { 'total' => 123, 'max_score' => 456, 'hits' => [] } }

    should "access klass, response, total and max_score" do
      r = DummyBaseClass.new OriginClass, RESPONSE

      assert_equal OriginClass, r.klass
      assert_equal RESPONSE, r.response
      assert_equal 123, r.total
      assert_equal 456, r.max_score
    end

    should "have abstract methods results and records" do
      r = DummyBaseClass.new OriginClass, RESPONSE

      assert_raise(Elasticsearch::Model::NotImplemented) { |e| r.results }
      assert_raise(Elasticsearch::Model::NotImplemented) { |e| r.records }
    end

  end
end
