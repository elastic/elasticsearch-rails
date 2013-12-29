require 'test_helper'

class Elasticsearch::Model::SearchingTest < Test::Unit::TestCase
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

    should "execute the search" do
      Elasticsearch::Model::Searching::SearchRequest
        .expects(:new).with do |klass, query, options|
          assert_equal DummySearchingModel, klass
          assert_equal 'foo', query
        end
        .returns( mock('search', execute!: {}) )

      DummySearchingModel.search 'foo'
    end
  end
end
