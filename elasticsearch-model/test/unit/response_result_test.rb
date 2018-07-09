require 'test_helper'
require 'active_support/json/encoding'

class Elasticsearch::Model::ResultTest < Test::Unit::TestCase
  context "Response result" do

    should "have method access to properties" do
      result = Elasticsearch::Model::Response::Result.new foo: 'bar', bar: { bam: 'baz' }

      assert_respond_to result, :foo
      assert_respond_to result, :bar

      assert_equal 'bar', result.foo
      assert_equal 'baz', result.bar.bam

      assert_raise(NoMethodError) { result.xoxo }
    end

    should "return _id as #id" do
      result = Elasticsearch::Model::Response::Result.new foo: 'bar', _id: 42, _source: { id: 12 }

      assert_equal 42, result.id
      assert_equal 12, result._source.id
    end

    should "return _type as #type" do
      result = Elasticsearch::Model::Response::Result.new foo: 'bar', _type: 'baz', _source: { type: 'BAM' }

      assert_equal 'baz', result.type
      assert_equal 'BAM', result._source.type
    end

    should "delegate method calls to `_source` when available" do
      result = Elasticsearch::Model::Response::Result.new foo: 'bar', _source: { bar: 'baz' }

      assert_respond_to result, :foo
      assert_respond_to result, :_source
      assert_respond_to result, :bar

      assert_equal 'bar', result.foo
      assert_equal 'baz', result._source.bar
      assert_equal 'baz', result.bar
    end

    should "delegate existence method calls to `_source`" do
      result = Elasticsearch::Model::Response::Result.new foo: 'bar', _source: { bar: { bam: 'baz' } }

      assert_respond_to result._source, :bar?
      assert_respond_to result, :bar?

      assert_equal true,  result._source.bar?
      assert_equal true,  result.bar?
      assert_equal false, result.boo?

      assert_equal true,  result.bar.bam?
      assert_equal false, result.bar.boo?
    end

    should "delegate methods to @result" do
      result = Elasticsearch::Model::Response::Result.new foo: 'bar'

      assert_equal 'bar',   result.foo
      assert_equal 'bar',   result.fetch('foo')
      assert_equal 'moo',   result.fetch('NOT_EXIST', 'moo')
      assert_equal ['foo'], result.keys

      assert_respond_to result, :to_hash
      assert_equal({'foo' => 'bar'}, result.to_hash)

      assert_raise(NoMethodError) { result.does_not_exist }
    end

    should "delegate existence method calls to @result" do
      result = Elasticsearch::Model::Response::Result.new foo: 'bar', _source: { bar: 'bam' }
      assert_respond_to result, :foo?

      assert_equal true,  result.foo?
      assert_equal false, result.boo?
      assert_equal false, result._source.foo?
      assert_equal false, result._source.boo?
    end

    should "delegate as_json to @result even when ActiveSupport changed half of Ruby" do
      result = Elasticsearch::Model::Response::Result.new foo: 'bar'

      result.instance_variable_get(:@result).expects(:as_json)
      result.as_json(except: 'foo')
    end
  end
end
