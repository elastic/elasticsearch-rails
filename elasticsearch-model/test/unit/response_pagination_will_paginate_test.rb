require 'test_helper'
require 'will_paginate'
require 'will_paginate/collection'

class Elasticsearch::Model::ResponsePaginationWillPaginateTest < Test::Unit::TestCase
  context "Response pagination" do
    class ModelClass
      def self.index_name;    'foo'; end
      def self.document_type; 'bar'; end

      # WillPaginate adds this method to models (see WillPaginate::PerPage module)
      def self.per_page
        33
      end
    end

    # Subsclass Response so we can include WillPaginate module without conflicts with Kaminari.
    class WillPaginateResponse < Elasticsearch::Model::Response::Response
      include Elasticsearch::Model::Response::Pagination::WillPaginate
    end

    RESPONSE = { 'took' => '5', 'timed_out' => false, '_shards' => {'one' => 'OK'},
                 'hits' => { 'total' => 100, 'hits' => (1..100).to_a.map { |i| { _id: i } } } }

    setup do
      @search   = Elasticsearch::Model::Searching::SearchRequest.new ModelClass, '*'
      @response = WillPaginateResponse.new ModelClass, @search, RESPONSE
      @response.klass.stubs(:client).returns mock('client')

      @expected_methods = [
        # methods needed by WillPaginate::CollectionMethods
        :current_page,
        :offset,
        :per_page,
        :total_entries,

        # methods defined by WillPaginate::CollectionMethods
        :total_pages,
        :previous_page,
        :next_page,
        :out_of_bounds?,
      ]
    end

    should "have pagination methods" do
      assert_respond_to @response, :paginate

      @expected_methods.each do |method|
        assert_respond_to @response, method
      end
    end

    context "response.results" do
      should "have pagination methods" do
        @expected_methods.each do |method|
          assert_respond_to @response.results, method
        end
      end
    end

    context "response.records" do
      should "have pagination methods" do
        @expected_methods.each do |method|
          @response.klass.stubs(:find).returns([])
          assert_respond_to @response.records, method
        end
      end
    end

    context "#offset method" do
      should "calculate offset using current_page and per_page" do
        @response.per_page(3).page(3)
        assert_equal 6, @response.offset
      end
    end

    context "#paginate method" do
      should "set from/size using defaults" do
        @response.klass.client
          .expects(:search)
            .with do |definition|
              assert_equal 0, definition[:from]
              assert_equal 33, definition[:size]
            end
          .returns(RESPONSE)

        assert_nil @response.search.definition[:from]
        assert_nil @response.search.definition[:size]

        @response.paginate(page: nil).to_a
        assert_equal 0, @response.search.definition[:from]
        assert_equal 33, @response.search.definition[:size]
      end

      should "set from/size using default per_page" do
        @response.klass.client
          .expects(:search)
            .with do |definition|
              assert_equal 33, definition[:from]
              assert_equal 33, definition[:size]
            end
          .returns(RESPONSE)

        assert_nil @response.search.definition[:from]
        assert_nil @response.search.definition[:size]

        @response.paginate(page: 2).to_a
        assert_equal 33, @response.search.definition[:from]
        assert_equal 33, @response.search.definition[:size]
      end

      should "set from/size using custom page and per_page" do
        @response.klass.client
          .expects(:search)
            .with do |definition|
              assert_equal 18, definition[:from]
              assert_equal 9, definition[:size]
            end
          .returns(RESPONSE)

        assert_nil @response.search.definition[:from]
        assert_nil @response.search.definition[:size]

        @response.paginate(page: 3, per_page: 9).to_a
        assert_equal 18, @response.search.definition[:from]
        assert_equal 9, @response.search.definition[:size]
      end

      should "searches for page 1 if specified page is < 1" do
        @response.klass.client
          .expects(:search)
            .with do |definition|
              assert_equal 0, definition[:from]
              assert_equal 33, definition[:size]
            end
          .returns(RESPONSE)

        assert_nil @response.search.definition[:from]
        assert_nil @response.search.definition[:size]

        @response.paginate(page: "-1").to_a
        assert_equal 0, @response.search.definition[:from]
        assert_equal 33, @response.search.definition[:size]
      end
    end

    context "#page and #per_page shorthand methods" do
      should "set from/size using default per_page" do
        @response.page(5)
        assert_equal 132, @response.search.definition[:from]
        assert_equal 33, @response.search.definition[:size]
      end

      should "set from/size when calling #page then #per_page" do
        @response.page(5).per_page(3)
        assert_equal 12, @response.search.definition[:from]
        assert_equal 3, @response.search.definition[:size]
      end

      should "set from/size when calling #per_page then #page" do
        @response.per_page(3).page(5)
        assert_equal 12, @response.search.definition[:from]
        assert_equal 3, @response.search.definition[:size]
      end
    end

    context "#current_page method" do
      should "return 1 by default" do
        @response.paginate({})
        assert_equal 1, @response.current_page
      end

      should "return current page number" do
        @response.paginate(page: 3, per_page: 9)
        assert_equal 3, @response.current_page
      end

      should "return nil if not pagination set" do
        assert_equal nil, @response.current_page
      end
    end

    context "#per_page method" do
      should "return value set in paginate call" do
        @response.paginate(per_page: 8)
        assert_equal 8, @response.per_page
      end
    end

    context "#total_entries method" do
      should "return total from response" do
        @response.expects(:results).returns(mock('results', total: 100))
        assert_equal 100, @response.total_entries
      end
    end
  end
end
