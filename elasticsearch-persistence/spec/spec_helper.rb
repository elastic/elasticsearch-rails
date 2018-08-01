require 'elasticsearch/persistence'

RSpec.configure do |config|
  config.formatter = 'documentation'
  config.color = true
end

class NoteRepository
  include Elasticsearch::Persistence::Repository
end

# The default client to be used by the repositories.
#
# @since 6.0.0
DEFAULT_CLIENT = Elasticsearch::Client.new(host: "localhost:#{(ENV['TEST_CLUSTER_PORT'] || 9250)}",
                                           tracer: (ENV['QUIET'] ? nil : ::Logger.new(STDERR)))

# The default client to be used by the repositories.
#
# @since 6.0.0
DEFAULT_REPOSITORY = NoteRepository.new(index_name: 'notes', document_type: 'note', client: DEFAULT_CLIENT)
