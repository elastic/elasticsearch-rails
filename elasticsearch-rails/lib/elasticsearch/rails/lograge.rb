module Elasticsearch
  module Rails
    module Lograge

      # Rails initializer class to require Elasticsearch::Rails::Instrumentation files,
      # set up Elasticsearch::Model and add Lograge configuration to display Elasticsearch-related duration
      #
      # Require the component in your `application.rb` file and enable Lograge:
      #
      #     require 'elasticsearch/rails/lograge'
      #
      # You should see the full duration of the request to Elasticsearch as part of each log event:
      #
      #     method=GET path=/search ... status=200 duration=380.89 view=99.64 db=0.00 es=279.37
      #
      # @see https://github.com/roidrage/lograge
      #
      class Railtie < ::Rails::Railtie
        initializer "elasticsearch.lograge" do |app|
          require 'elasticsearch-rails/lib/elasticsearch/rails/lograge_modules'

          config.lograge.custom_options = lambda do |event|
            { es: event.payload[:elasticsearch_runtime].to_f.round(2) }
          end
        end
      end

    end
  end
end
