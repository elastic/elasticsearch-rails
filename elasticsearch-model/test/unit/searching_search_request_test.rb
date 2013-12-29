require 'test_helper'

class Elasticsearch::Model::SearchRequestTest < Test::Unit::TestCase
  context "SearchRequest class" do
    class ::DummySearchingModel
      extend Elasticsearch::Model::Searching::ClassMethods

      def self.index_name;    'foo'; end
      def self.document_type; 'bar'; end

    end

    setup do
      @client = mock('client')
      DummySearchingModel.stubs(:client).returns(@client)
    end

    should "pass the search definition as a simple query" do
      @client.expects(:search).with do |params|
        assert_equal 'foo', params[:q]
      end
      .returns({})

      s = Elasticsearch::Model::Searching::SearchRequest.new ::DummySearchingModel, 'foo'
      s.execute!
    end

    should "pass the search definition as a Hash" do
      @client.expects(:search).with do |params|
        assert_equal( {foo: 'bar'}, params[:body] )
      end
      .returns({})

      s = Elasticsearch::Model::Searching::SearchRequest.new ::DummySearchingModel, foo: 'bar'
      s.execute!
    end

    should "pass the search definition as a JSON string" do
      @client.expects(:search).with do |params|
        assert_equal( '{"foo":"bar"}', params[:body] )
      end
      .returns({})

      s = Elasticsearch::Model::Searching::SearchRequest.new ::DummySearchingModel, '{"foo":"bar"}'
      s.execute!
    end

    should "pass the search definition as an object which responds to to_hash" do
      class MySpecialQueryBuilder
        def to_hash; {foo: 'bar'}; end
      end

      @client.expects(:search).with do |params|
        assert_equal( {foo: 'bar'}, params[:body] )
      end
      .returns({})

      s = Elasticsearch::Model::Searching::SearchRequest.new ::DummySearchingModel, MySpecialQueryBuilder.new
      s.execute!
    end
  end
end
