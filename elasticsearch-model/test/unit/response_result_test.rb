require 'test_helper'

class Elasticsearch::Model::ResultTest < Test::Unit::TestCase
  context "Response result" do

    should "have method access to properties" do
      assert_respond_to result, :foo
      assert_respond_to result, :bar

      assert_equal 'bar', result.foo
      assert_equal 'baz', result.bar.bam

      assert_raise(NoMethodError) { result.xoxo }
    end

    should "delegate method calls to `_source` when available" do
      assert_respond_to result, :foo
      assert_respond_to result, :_source
      assert_respond_to result, :bar

      assert_equal 'bar', result.foo
      assert_equal 'baz', result._source.bar.bam
      assert_equal 'baz', result.bar.bam

      assert_equal 'bar', result.fetch('foo')
      assert_equal 'moo', result.fetch('NOT_EXIST', 'moo')
    end

    should "delegate existence method calls to `_source`" do
      assert_respond_to result, :bar?
      assert_respond_to result._source, :bar?

      assert_equal true, result._source.bar?
      assert_equal true, result.bar?
      assert_equal false, result.baz?

      assert_equal true, result.bar.bam?
      assert_equal false, result.bar.boo?
    end

    should "delegate methods to _source" do
      assert_respond_to result, :to_hash
      assert_equal({'foo' => 'bar', 'bar' => {'bam' => 'baz'}}, result.to_hash)

      assert_raise(NoMethodError) { result.does_not_exist }
    end

    should "respond to highlight" do
      assert_respond_to result, :highlight
      assert_respond_to result, :highlight?

      assert_equal({"foo"=>["<em>bar</em>"]}, result.highlight)
      assert_equal true, result.highlight?

      no_highlight = Elasticsearch::Model::Response::Result.new({foo: 'bar'})
      assert_equal nil, no_highlight.highlight
      assert_equal false, no_highlight.highlight?
    end

    should "delegate as_json to @result even when ActiveSupport changed half of Ruby" do
      require 'active_support/json/encoding'
      result = Elasticsearch::Model::Response::Result.new(example_response)

      result.instance_variable_get(:@attributes).expects(:as_json)
      result.as_json(except: 'foo')
    end

    should "have a working to_s method" do
      assert_equal example_response, JSON.parse(result.to_s)
    end

    should "have a working inspect method" do
      assert_equal example_response, JSON.parse(result.inspect)
    end
  end

  def result
    Elasticsearch::Model::Response::Result.new(example_response)
  end

  def example_response
    {
      "_index" => "foo_index",
      "_type" => "foo",
      "_id" => "1",
      "_score" => 1.0,
      "_source" => {
        "foo" => "bar",
        "bar" => {
          "bam" => "baz"
        }
      },
      "highlight" => {
        "foo" => ["<em>bar</em>"]
      }
    }
  end
end
