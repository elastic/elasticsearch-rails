require 'test_helper'

class Elasticsearch::Model::ResponsePaginationKaminariTest < Test::Unit::TestCase
  context "Response pagination" do
    class ModelClass
      include ::Kaminari::ConfigurationMethods

      def self.index_name;    'foo'; end
      def self.document_type; 'bar'; end
    end

    RESPONSE = { 'took' => '5', 'timed_out' => false, '_shards' => {'one' => 'OK'},
                 'hits' => { 'total' => 100, 'hits' => (1..100).to_a.map { |i| { _id: i } } } }

    setup do
      @search   = Elasticsearch::Model::Searching::SearchRequest.new ModelClass, '*'
      @response = Elasticsearch::Model::Response::Response.new ModelClass, @search, RESPONSE
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
              true
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
              true
            end
          .returns(RESPONSE)

        @response.page(4).to_a
        assert_equal 75, @response.search.definition[:from]
        assert_equal 25, @response.search.definition[:size]
      end
    end

    context "limit/offset readers" do
      should "return the default" do
        assert_equal Kaminari.config.default_per_page, @response.limit_value
        assert_equal 0, @response.offset_value
      end

      should "return the value from URL parameters" do
        search    = Elasticsearch::Model::Searching::SearchRequest.new ModelClass, '*', size: 10, from: 50
        @response = Elasticsearch::Model::Response::Response.new ModelClass, search, RESPONSE

        assert_equal 10, @response.limit_value
        assert_equal 50, @response.offset_value
      end

      should "ignore the value from request body" do
        search    = Elasticsearch::Model::Searching::SearchRequest.new ModelClass,
                    { query: { match_all: {} }, from: 333, size: 999 }
        @response = Elasticsearch::Model::Response::Response.new ModelClass, search, RESPONSE

        assert_equal Kaminari.config.default_per_page, @response.limit_value
        assert_equal 0, @response.offset_value
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
        @response.limit(35)

        assert_nil @response.instance_variable_get(:@response)
        assert_nil @response.instance_variable_get(:@records)
        assert_nil @response.instance_variable_get(:@results)
      end
    end

    context "with the page() and limit() methods" do
      setup do
        @response.records
        @response.results
      end

      should "set the values" do
        @response.page(3).limit(35)
        assert_equal 35, @response.search.definition[:size]
        assert_equal 70, @response.search.definition[:from]
      end

      should "set the values when limit is called first" do
        @response.limit(35).page(3)
        assert_equal 35, @response.search.definition[:size]
        assert_equal 70, @response.search.definition[:from]
      end

      should "reset the instance variables" do
        @response.page(3).limit(35)

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
        @response.offset(35)

        assert_nil @response.instance_variable_get(:@response)
        assert_nil @response.instance_variable_get(:@records)
        assert_nil @response.instance_variable_get(:@results)
      end
    end

    context "total" do
      should "return the number of hits" do
        @response.expects(:results).returns(mock('results', total: 100))
        assert_equal 100, @response.total_count
      end
    end

    context "results" do
      setup do
        @search.stubs(:execute!).returns RESPONSE
      end

      should "return current page and total count" do
        assert_equal 1, @response.page(1).results.current_page
        assert_equal 100, @response.results.total_count

        assert_equal 5, @response.page(5).results.current_page
      end
    end

    context "records" do
      setup do
        @search.stubs(:execute!).returns RESPONSE
      end

      should "return current page and total count" do
        assert_equal 1, @response.page(1).records.current_page
        assert_equal 100, @response.records.total_count

        assert_equal 5, @response.page(5).records.current_page
      end
    end
  end
end
