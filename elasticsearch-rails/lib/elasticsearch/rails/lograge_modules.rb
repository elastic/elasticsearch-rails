require 'elasticsearch/rails/instrumentation/publishers'
require 'elasticsearch/rails/instrumentation/log_subscriber'
require 'elasticsearch/rails/instrumentation/controller_runtime'

Elasticsearch::Model::Searching::SearchRequest.class_eval do
  include Elasticsearch::Rails::Instrumentation::Publishers::SearchRequest
end if defined?(Elasticsearch::Model::Searching::SearchRequest)

Elasticsearch::Persistence::Model::Find::SearchRequest.class_eval do
  include Elasticsearch::Rails::Instrumentation::Publishers::SearchRequest
end if defined?(Elasticsearch::Persistence::Model::Find::SearchRequest)

ActiveSupport.on_load(:action_controller) do
  include Elasticsearch::Rails::Instrumentation::ControllerRuntime
end
