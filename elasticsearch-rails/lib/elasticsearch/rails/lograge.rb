# Licensed to Elasticsearch B.V. under one or more contributor
# license agreements. See the NOTICE file distributed with
# this work for additional information regarding copyright
# ownership. Elasticsearch B.V. licenses this file to you under
# the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#	http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

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
          require 'elasticsearch/rails/instrumentation/publishers'
          require 'elasticsearch/rails/instrumentation/log_subscriber'
          require 'elasticsearch/rails/instrumentation/controller_runtime'

          Elasticsearch::Model::Searching::SearchRequest.class_eval do
            include Elasticsearch::Rails::Instrumentation::Publishers::SearchRequest
          end if defined?(Elasticsearch::Model::Searching::SearchRequest)

          ActiveSupport.on_load(:action_controller) do
            include Elasticsearch::Rails::Instrumentation::ControllerRuntime
          end

          config.lograge.custom_options = lambda do |event|
            { es: event.payload[:elasticsearch_runtime].to_f.round(2) }
          end
        end
      end

    end
  end
end
