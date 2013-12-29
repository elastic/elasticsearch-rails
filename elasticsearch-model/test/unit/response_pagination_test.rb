require 'test_helper'

class Elasticsearch::Model::ResponsePaginationTest < Test::Unit::TestCase
  context "Response pagination" do
    class ModelClass
      include ::Kaminari::ConfigurationMethods

      def self.index_name;    'foo'; end
      def self.document_type; 'bar'; end
    end

    RESPONSE = { 'took' => '5', 'timed_out' => false, '_shards' => {'one' => 'OK'},
                 'hits' => { 'total' => 100, 'hits' => [ {'_id' => 1} ] } }

    setup do
      search    = Elasticsearch::Model::Searching::SearchRequest.new ModelClass, '*'
      @response = Elasticsearch::Model::Response::Response.new ModelClass, search, RESPONSE
      @response.klass.stubs(:client).returns mock('client')
    end

    should "have pagination methods" do
      assert_respond_to @response, :page
      assert_respond_to @response, :limit_value
      assert_respond_to @response, :offset_value
      assert_respond_to @response, :limit
      assert_respond_to @response, :offset
      assert_respond_to @response, :total_count
    end

    context "#page method" do
      should "advance the from/size" do
        @response.klass.client
          .expects(:search)
            .with do |definition|
              assert_equal 25, definition[:from]
              assert_equal 25, definition[:size]
            end
          .returns(RESPONSE)

        assert_nil @response.search.definition[:from]
        assert_nil @response.search.definition[:size]

        @response.page(2).to_a
        assert_equal 25, @response.search.definition[:from]
        assert_equal 25, @response.search.definition[:size]
      end

      should "advance the from/size further" do
        @response.klass.client
          .expects(:search)
            .with do |definition|
              assert_equal 75, definition[:from]
              assert_equal 25, definition[:size]
            end
          .returns(RESPONSE)

        @response.page(4).to_a
        assert_equal 75, @response.search.definition[:from]
        assert_equal 25, @response.search.definition[:size]
      end
    end

    context "limit/offset readers" do
      should "return the default" do
        assert_equal 0, @response.limit_value
        assert_equal 0, @response.offset_value
      end

      should "return the value from URL parameters" do
        search    = Elasticsearch::Model::Searching::SearchRequest.new ModelClass, '*', size: 10, from: 50
        @response = Elasticsearch::Model::Response::Response.new ModelClass, search, RESPONSE

        assert_equal 10, @response.limit_value
        assert_equal 50, @response.offset_value
      end

      should "return the value from body" do
        search    = Elasticsearch::Model::Searching::SearchRequest.new ModelClass, { query: { match_all: {} }, from: 10, size: 50 }
        @response = Elasticsearch::Model::Response::Response.new ModelClass, search, RESPONSE

        assert_equal 50, @response.limit_value
        assert_equal 10, @response.offset_value
      end
    end

    context "limit setter" do
      setup do
        @response.records
        @response.results
      end

      should "set the values" do
        @response.limit(35)
        assert_equal 35, @response.search.definition[:size]
      end

      should "reset the variables" do
        assert_not_nil @response.instance_variable_get(:@response)
        assert_not_nil @response.instance_variable_get(:@records)
        assert_not_nil @response.instance_variable_get(:@results)

        @response.limit(35)

        assert_nil @response.instance_variable_get(:@response)
        assert_nil @response.instance_variable_get(:@records)
        assert_nil @response.instance_variable_get(:@results)
      end
    end

    context "offset setter" do
      setup do
        @response.records
        @response.results
      end

      should "set the values" do
        @response.offset(15)
        assert_equal 15, @response.search.definition[:from]
      end

      should "reset the variables" do
        assert_not_nil @response.instance_variable_get(:@response)
        assert_not_nil @response.instance_variable_get(:@records)
        assert_not_nil @response.instance_variable_get(:@results)

        @response.offset(35)

        assert_nil @response.instance_variable_get(:@response)
        assert_nil @response.instance_variable_get(:@records)
        assert_nil @response.instance_variable_get(:@results)
      end
    end

    context "total" do
      should "return the number of hits" do
        assert_equal 100, @response.total_count
      end
    end
  end
end
