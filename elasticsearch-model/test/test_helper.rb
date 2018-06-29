RUBY_1_8 = defined?(RUBY_VERSION) && RUBY_VERSION < '1.9'

exit(0) if RUBY_1_8

require 'simplecov' and SimpleCov.start { add_filter "/test|test_/" } if ENV["COVERAGE"]

# Register `at_exit` handler for integration tests shutdown.
# MUST be called before requiring `test/unit`.
at_exit { Elasticsearch::Test::IntegrationTestCase.__run_at_exit_hooks }

puts '-'*80

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
        logger.formatter = lambda { |s, d, p, m| "\e[2;36m#{m}\e[0m\n" }
        ActiveRecord::Base.logger = logger unless ENV['QUIET']

        ActiveRecord::LogSubscriber.colorize_logging = false
        ActiveRecord::Migration.verbose = false

        tracer = ::Logger.new(STDERR)
        tracer.formatter = lambda { |s, d, p, m| "#{m.gsub(/^.*$/) { |n| '   ' + n }.ansi(:faint)}\n" }

        Elasticsearch::Model.client = Elasticsearch::Client.new host: "localhost:#{(ENV['TEST_CLUSTER_PORT'] || 9250)}",
                                                                tracer: (ENV['QUIET'] ? nil : tracer)
      end
    end
  end
end

class MongoDB
  def self.setup!
    begin
      require 'mongoid'
      Mongo::Client.new(["localhost:27017"])
      ENV['MONGODB_AVAILABLE'] = 'yes'
    rescue LoadError, Mongo::Error => e
      $stderr.puts "MongoDB not installed or running: #{e}"
    end
  end

  def self.available?
    !!ENV['MONGODB_AVAILABLE']
  end

  def self.connect_to(source)
    $stderr.puts "Mongoid #{Mongoid::VERSION}", '-'*80

    logger = ::Logger.new($stderr)
    logger.formatter = lambda { |s, d, p, m| " #{m.ansi(:faint, :cyan)}\n" }
    logger.level = ::Logger::DEBUG

    Mongoid.logger = logger unless ENV['QUIET']
    Mongo::Logger.logger   = logger unless ENV['QUIET']

    Mongoid.connect_to source
  end
end
