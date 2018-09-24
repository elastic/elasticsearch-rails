require 'pry-nav'
require 'active_record'
require 'elasticsearch/model'
require 'elasticsearch/rails'
require 'rails/railtie'
require 'elasticsearch/rails/instrumentation'


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

    if ::ActiveRecord::Base.respond_to?(:raise_in_transactional_callbacks) && ::ActiveRecord::VERSION::MAJOR.to_s < '5'
      ::ActiveRecord::Base.raise_in_transactional_callbacks = true
    end
  end
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
