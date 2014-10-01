module Elasticsearch
  module Rails
    module Instrumentation

      # Rails initializer class to require Elasticsearch::Rails::Instrumentation files,
      # set up Elasticsearch::Model and hook into ActionController to display Elasticsearch-related duration
      #
      # @see http://edgeguides.rubyonrails.org/active_support_instrumentation.html
      #
      class Railtie < ::Rails::Railtie
        initializer "elasticsearch.instrumentation" do |app|
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
        end
      end

    end
  end
end
