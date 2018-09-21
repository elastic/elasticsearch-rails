require 'pry-nav'
require 'kaminari'
require 'kaminari/version'
require 'will_paginate'
require 'will_paginate/collection'
require 'elasticsearch/model'
require 'hashie/version'
require 'active_model'
require 'mongoid'
require 'yaml'
require 'active_record'

unless defined?(ELASTICSEARCH_URL)
  ELASTICSEARCH_URL = ENV['ELASTICSEARCH_URL'] || "localhost:#{(ENV['TEST_CLUSTER_PORT'] || 9200)}"
end

RSpec.configure do |config|
  config.formatter = 'documentation'
  config.color = true

  config.before(:suite) do
    require 'ansi'
    tracer = ::Logger.new(STDERR)
    tracer.formatter = lambda { |s, d, p, m| "#{m.gsub(/^.*$/) { |n| '   ' + n }.ansi(:faint)}\n" }
    Elasticsearch::Model.client = Elasticsearch::Client.new host: ELASTICSEARCH_URL,
                                                            tracer: (ENV['QUIET'] ? nil : tracer)

    unless ActiveRecord::Base.connected?
      ActiveRecord::Base.establish_connection( :adapter => 'sqlite3', :database => ":memory:" )
    end
    require 'support/app'

    if ::ActiveRecord::Base.respond_to?(:raise_in_transactional_callbacks) && ::ActiveRecord::VERSION::MAJOR.to_s < '5'
      ::ActiveRecord::Base.raise_in_transactional_callbacks = true
    end
  end

  config.after(:all) do
    drop_all_tables!
    delete_all_indices!
  end
end

# Is the ActiveRecord version at least 4.0?
#
# @return [ true, false ] Whether the ActiveRecord version is at least 4.0.
#
# @since 6.0.1
def active_record_at_least_4?
  defined?(::ActiveRecord) && ::ActiveRecord::VERSION::MAJOR >= 4
end

# Delete all documents from the indices of the provided list of models.
#
# @param [ Array<ActiveRecord::Base> ] models The list of models.
#
# @return [ true ]
#
# @since 6.0.1
def clear_indices(*models)
  models.each do |model|
    begin; Elasticsearch::Model.client.delete_by_query(index: model.index_name, q: '*'); rescue; end
  end and true
end

# Delete all documents from the tables of the provided list of models.
#
# @param [ Array<ActiveRecord::Base> ] models The list of models.
#
# @return [ true ]
#
# @since 6.0.1
def clear_tables(*models)
  begin; models.map(&:delete_all); rescue; end and true
end

# Drop all tables of models registered as subclasses of ActiveRecord::Base.
#
# @return [ true ]
#
# @since 6.0.1
def drop_all_tables!
  ActiveRecord::Base.descendants.each do |model|
    begin
      ActiveRecord::Schema.define do
        drop_table model
      end if model.table_exists?
    rescue
    end
  end and true
end

# Drop all indices of models registered as subclasses of ActiveRecord::Base.
#
# @return [ true ]
#
# @since 6.0.1
def delete_all_indices!
  client = Elasticsearch::Model.client
  ActiveRecord::Base.descendants.each do |model|
    begin
      client.indices.delete(index: model.index_name) if model.__elasticsearch__.index_exists?
    rescue
    end
  end and true
end

# Remove all classes.
#
# @param [ Array<Class> ] classes The list of classes to remove.
#
# @return [ true ]
#
# @since 6.0.1
def remove_classes(*classes)
  classes.each do |_class|
    Object.send(:remove_const, _class.name.to_sym) if defined?(_class)
  end and true
end

# Determine whether the tests with Mongoid should be run.
# Depends on whether MongoDB is running on the default host and port, `localhost:27017`.
#
# @return [ true, false ]
#
# @since 6.0.1
def test_mongoid?
  $mongoid_available ||= begin
    require 'mongoid'
    if defined?(Mongo) # older versions of Mongoid use the driver, Moped
      client = Mongo::Client.new(['localhost:27017'])
      Timeout.timeout(1) do
        client.database.command(ping: 1) && true
      end
    end and true
  rescue Timeout::Error, LoadError, Mongo::Error => e
    client.close
    $stderr.puts("MongoDB not installed or running: #{e}")
  end
end

# Connect Mongoid and set up its Logger if Mongoid tests should be run.
#
# @since 6.0.1
def connect_mongoid(source)
  if test_mongoid?
    $stderr.puts "Mongoid #{Mongoid::VERSION}", '-'*80

    if !ENV['QUIET'] == 'true'
      logger = ::Logger.new($stderr)
      logger.formatter = lambda { |s, d, p, m| " #{m.ansi(:faint, :cyan)}\n" }
      logger.level = ::Logger::DEBUG
      Mongoid.logger = logger
      Mongo::Logger.logger = logger
    else
      Mongo::Logger.logger.level = ::Logger::WARN
    end

    Mongoid.connect_to(source)
  end
end
