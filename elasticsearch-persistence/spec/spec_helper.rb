require 'elasticsearch/persistence'

# The default client to be used by the repositories.
#
# @since 6.0.0
DEFAULT_CLIENT = Elasticsearch::Client.new(host: "localhost:#{(ENV['TEST_CLUSTER_PORT'] || 9250)}",
                                           tracer: (ENV['QUIET'] ? nil : tracer))

RSpec.configure do |config|
  config.formatter = 'documentation'
  config.color = true

  config.before(:suite) do
    Elasticsearch::Persistence::Repository::Base.client = DEFAULT_CLIENT
  end
end
