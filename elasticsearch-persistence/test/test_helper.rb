$LOAD_PATH.unshift File.expand_path('../../../elasticsearch-model/lib', __FILE__) if File.exists? File.expand_path('../../../elasticsearch-model/lib', __FILE__)

require 'simplecov' and SimpleCov.start { add_filter "/test|test_/" } if ENV["COVERAGE"]

# Register `at_exit` handler for integration tests shutdown.
# MUST be called before requiring `test/unit`.
at_exit { Elasticsearch::Test::IntegrationTestCase.__run_at_exit_hooks } if ENV['SERVER']

if defined?(RUBY_VERSION) && RUBY_VERSION > '2.2'
  require 'test-unit'
  require 'mocha/test_unit'
else
  require 'minitest/autorun'
  require 'mocha/mini_test'
end

require 'shoulda-context'

require 'turn' unless ENV["TM_FILEPATH"] || ENV["NOTURN"] || defined?(RUBY_VERSION) && RUBY_VERSION > '2.2'

require 'ansi'
require 'oj'

require 'elasticsearch/extensions/test/cluster'
require 'elasticsearch/extensions/test/startup_shutdown'

require 'elasticsearch/persistence'

module Elasticsearch
  module Test
    class IntegrationTestCase < ::Test::Unit::TestCase
      extend Elasticsearch::Extensions::Test::StartupShutdown

      startup  { Elasticsearch::Extensions::Test::Cluster.start(nodes: 1) if ENV['SERVER'] and not Elasticsearch::Extensions::Test::Cluster.running? }
      shutdown { Elasticsearch::Extensions::Test::Cluster.stop if ENV['SERVER'] && started? }

      def setup
        tracer = ::Logger.new(STDERR)
        tracer.formatter = lambda { |s, d, p, m| "#{m.gsub(/^.*$/) { |n| '   ' + n }.ansi(:faint)}\n" }
        Elasticsearch::Persistence.client = Elasticsearch::Client.new \
                                              host: "localhost:#{(ENV['TEST_CLUSTER_PORT'] || 9250)}",
                                              tracer: (ENV['QUIET'] ? nil : tracer)
      end

      def teardown
        Elasticsearch::Persistence.client.indices.delete index: '_all'
      end
    end
  end
end
