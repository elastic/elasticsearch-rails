require 'test_helper'

class Elasticsearch::Model::SearchTest < Test::Unit::TestCase
  context "Searching module" do
    class ::DummySearchingModel
      extend Elasticsearch::Model::Searching::ClassMethods

      def self.index_name;    'foo'; end
      def self.document_type; 'bar'; end

    end

    setup do
      @client = mock('client')
      DummySearchingModel.stubs(:client).returns(@client)
    end

    should "have the search method" do
      assert_respond_to DummySearchingModel, :search
    end

    should "pass the search definition as simple query" do
      @client.expects(:search).with do |params|
        assert_equal 'foo', params[:q]
      end
      .returns({})

      DummySearchingModel.search 'foo'
    end

    should "pass the search definition as a Hash" do
      @client.expects(:search).with do |params|
        assert_equal( {foo: 'bar'}, params[:body] )
      end
      .returns({})

      DummySearchingModel.search foo: 'bar'
    end

    should "pass the search definition as a JSON string" do
      @client.expects(:search).with do |params|
        assert_equal( '{"foo":"bar"}', params[:body] )
      end
      .returns({})

      DummySearchingModel.search '{"foo":"bar"}'
    end

    should "pass the search definition as an object which responds to to_hash" do
      class MySpecialQueryBuilder
        def to_hash; {foo: 'bar'}; end
      end

      @client.expects(:search).with do |params|
        assert_equal( {foo: 'bar'}, params[:body] )
      end
      .returns({})

      DummySearchingModel.search MySpecialQueryBuilder.new
    end
  end
end
