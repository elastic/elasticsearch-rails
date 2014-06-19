require 'test_helper'

require 'rails/railtie'
require 'active_support/log_subscriber/test_helper'

require 'elasticsearch/rails/instrumentation'

class Elasticsearch::Rails::InstrumentationTest < Test::Unit::TestCase
  include ActiveSupport::LogSubscriber::TestHelper

  context "ActiveSupport::Instrumentation integration" do
    class ::DummyInstrumentationModel
      extend Elasticsearch::Model::Searching::ClassMethods

      def self.index_name;    'foo'; end
      def self.document_type; 'bar'; end
    end

    RESPONSE = { 'took' => '5ms', 'hits' => { 'total' => 123, 'max_score' => 456, 'hits' => [] } }

    setup do
      @search   = Elasticsearch::Model::Searching::SearchRequest.new ::DummyInstrumentationModel, '*'

      @client = stub('client', search: RESPONSE)
      DummyInstrumentationModel.stubs(:client).returns(@client)

      Elasticsearch::Rails::Instrumentation::Railtie.run_initializers
    end

    should "wrap SearchRequest#execute! with instrumentation" do
      s = Elasticsearch::Model::Searching::SearchRequest.new ::DummyInstrumentationModel, 'foo'
      assert_respond_to s, :execute_without_instrumentation!
      assert_respond_to s, :execute_with_instrumentation!
    end

    should "publish the notification" do
      @query = { query: { match: { foo: 'bar' } } }

      ActiveSupport::Notifications.expects(:instrument).with do |name, payload|
        assert_equal "search.elasticsearch", name
        assert_equal 'DummyInstrumentationModel', payload[:klass]
        assert_equal @query, payload[:search][:body]
      end

      s = ::DummyInstrumentationModel.search @query
      s.response
    end

    should "print the debug information to the Rails log" do
      s = ::DummyInstrumentationModel.search query: { match: { moo: 'bam' } }
      s.response

      logged = @logger.logged(:debug).first

      assert_not_nil logged
      assert_match /DummyInstrumentationModel Search \(\d+\.\d+ms\)/,  logged
      assert_match /body\: \{query\: \{match\: \{moo\: "bam"\}\}\}\}/, logged
    end
  end
end
