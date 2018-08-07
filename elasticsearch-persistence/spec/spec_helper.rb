require 'elasticsearch/persistence'

RSpec.configure do |config|
  config.formatter = 'documentation'
  config.color = true
end

# The default client to be used by the repositories.
#
# @since 6.0.0
DEFAULT_CLIENT = Elasticsearch::Client.new(host: "localhost:#{(ENV['TEST_CLUSTER_PORT'] || 9250)}",
                                           tracer: (ENV['QUIET'] ? nil : ::Logger.new(STDERR)))

class MyTestRepository
  include Elasticsearch::Persistence::Repository
  client DEFAULT_CLIENT
end

# The default repository to be used by tests.
#
# @since 6.0.0
DEFAULT_REPOSITORY = MyTestRepository.new(index_name: 'my_test_repository', document_type: 'test')
