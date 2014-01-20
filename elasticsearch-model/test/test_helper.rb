RUBY_1_8 = defined?(RUBY_VERSION) && RUBY_VERSION < '1.9'

exit(0) if RUBY_1_8

require 'simplecov' and SimpleCov.start { add_filter "/test|test_/" } if ENV["COVERAGE"]

# Register `at_exit` handler for integration tests shutdown.
# MUST be called before requiring `test/unit`.
at_exit { Elasticsearch::Test::IntegrationTestCase.__run_at_exit_hooks }

puts '-'*80

require 'test/unit'
require 'shoulda-context'
require 'mocha/setup'
require 'turn' unless ENV["TM_FILEPATH"] || ENV["NOTURN"] || RUBY_1_8

require 'ansi'
require 'oj'

require 'active_record'
require 'active_model'

require 'kaminari'

require 'elasticsearch/model'

require 'elasticsearch/extensions/test/cluster'
require 'elasticsearch/extensions/test/startup_shutdown'

module Elasticsearch
  module Test
    class IntegrationTestCase < ::Test::Unit::TestCase
      extend Elasticsearch::Extensions::Test::StartupShutdown

      startup  { Elasticsearch::Extensions::Test::Cluster.start(nodes: 1) if ENV['SERVER'] and not Elasticsearch::Extensions::Test::Cluster.running? }
      shutdown { Elasticsearch::Extensions::Test::Cluster.stop if ENV['SERVER'] && started? }
      context "IntegrationTest" do; should "noop on Ruby 1.8" do; end; end if RUBY_1_8

      def setup
        ActiveRecord::Base.establish_connection( :adapter => 'sqlite3', :database => ":memory:" )
        logger = ::Logger.new(STDERR)
        logger.formatter = lambda { |s, d, p, m| "#{m.ansi(:faint, :cyan)}\n" }
        ActiveRecord::Base.logger = logger unless ENV['QUIET']

        ActiveRecord::LogSubscriber.colorize_logging = false
        ActiveRecord::Migration.verbose = false

        tracer = ::Logger.new(STDERR)
        tracer.formatter = lambda { |s, d, p, m| "#{m.gsub(/^.*$/) { |n| '   ' + n }.ansi(:faint)}\n" }

        Elasticsearch::Model.client = Elasticsearch::Client.new host: 'localhost:9250',
                                                                tracer: (ENV['QUIET'] ? nil : tracer)
      end
    end
  end
end
