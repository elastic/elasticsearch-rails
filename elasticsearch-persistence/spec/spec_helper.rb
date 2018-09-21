require 'pry-nav'
require 'elasticsearch/persistence'

unless defined?(ELASTICSEARCH_URL)
  ELASTICSEARCH_URL = ENV['ELASTICSEARCH_URL'] || "localhost:#{(ENV['TEST_CLUSTER_PORT'] || 9200)}"
end

RSpec.configure do |config|
  config.formatter = 'documentation'
  config.color = true

  config.after(:suite) do
    DEFAULT_CLIENT.indices.delete(index: '_all')
  end
end

# The default client to be used by the repositories.
#
# @since 6.0.0
DEFAULT_CLIENT = Elasticsearch::Client.new(host: ELASTICSEARCH_URL,
                                           tracer: (ENV['QUIET'] ? nil : ::Logger.new(STDERR)))

class MyTestRepository
  include Elasticsearch::Persistence::Repository
  include Elasticsearch::Persistence::Repository::DSL
  client DEFAULT_CLIENT
end

# The default repository to be used by tests.
#
# @since 6.0.0
DEFAULT_REPOSITORY = MyTestRepository.new(index_name: 'my_test_repository', document_type: 'test')
