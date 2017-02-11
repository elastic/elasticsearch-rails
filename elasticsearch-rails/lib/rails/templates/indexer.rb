# Indexer class for <http://sidekiq.org>
#
# Run me with:
#
#     $ bundle exec sidekiq --queue elasticsearch --verbose
#
class Indexer
  include Sidekiq::Worker
  sidekiq_options queue: 'elasticsearch', retry: false, backtrace: true

  Logger = Sidekiq.logger.level == Logger::DEBUG ? Sidekiq.logger : nil
  Client = Elasticsearch::Client.new host: (ENV['ELASTICSEARCH_URL'] || 'http://localhost:9200'), logger: Logger

  def perform(operation, klass, record_id, options = {})
    logger.debug [operation, "#{klass}##{record_id} #{options.inspect}"]

    raise ArgumentError, "Unknown operation '#{operation}'" unless %w(index update delete).include?(operation.to_s)

    record = klass.constantize.find(record_id)
    record.__elasticsearch__.client = Client
    record.__elasticsearch__.__send__ "#{operation}_document", options
  end
end
