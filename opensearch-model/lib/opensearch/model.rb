# Licensed to Elasticsearch B.V. under one or more contributor
# license agreements. See the NOTICE file distributed with
# this work for additional information regarding copyright
# ownership. Elasticsearch B.V. licenses this file to you under
# the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

require 'hashie/mash'

require 'active_support/core_ext/module/delegation'

require 'opensearch-ruby'

require 'opensearch/model/version'

require 'opensearch/model/hash_wrapper'
require 'opensearch/model/client'

require 'opensearch/model/multimodel'

require 'opensearch/model/adapter'
require 'opensearch/model/adapters/default'
require 'opensearch/model/adapters/active_record'
require 'opensearch/model/adapters/mongoid'
require 'opensearch/model/adapters/multiple'

require 'opensearch/model/importing'
require 'opensearch/model/indexing'
require 'opensearch/model/naming'
require 'opensearch/model/serializing'
require 'opensearch/model/searching'
require 'opensearch/model/callbacks'

require 'opensearch/model/proxy'

require 'opensearch/model/response'
require 'opensearch/model/response/base'
require 'opensearch/model/response/result'
require 'opensearch/model/response/results'
require 'opensearch/model/response/records'
require 'opensearch/model/response/pagination'
require 'opensearch/model/response/aggregations'
require 'opensearch/model/response/suggestions'

require 'opensearch/model/ext/active_record'

case
when defined?(::Kaminari)
  OpenSearch::Model::Response::Response.__send__ :include, OpenSearch::Model::Response::Pagination::Kaminari
when defined?(::WillPaginate)
  OpenSearch::Model::Response::Response.__send__ :include, OpenSearch::Model::Response::Pagination::WillPaginate
end

module OpenSearch

  # OpenSearch integration for Ruby models
  # =========================================
  #
  # `OpenSearch::Model` contains modules for integrating the OpenSearch search and analytical engine
  # with ActiveModel-based classes, or models, for the Ruby programming language.
  #
  # It facilitates importing your data into an index, automatically updating it when a record changes,
  # searching the specific index, setting up the index mapping or the model JSON serialization.
  #
  # When the `OpenSearch::Model` module is included in your class, it automatically extends it
  # with the functionality; see {OpenSearch::Model.included}. Most methods are available via
  # the `__opensearch__` class and instance method proxies.
  #
  # It is possible to include/extend the model with the corresponding
  # modules directly, if that is desired:
  #
  #     MyModel.__send__ :extend,  OpenSearch::Model::Client::ClassMethods
  #     MyModel.__send__ :include, OpenSearch::Model::Client::InstanceMethods
  #     MyModel.__send__ :extend,  OpenSearch::Model::Searching::ClassMethods
  #     # ...
  #
  module Model
    METHODS = [:search, :mapping, :mappings, :settings, :index_name, :document_type, :import]

    # Adds the `OpenSearch::Model` functionality to the including class.
    #
    # * Creates the `__opensearch__` class and instance method. These methods return a proxy object with
    #   other common methods defined on them.
    # * The module includes other modules with further functionality.
    # * Sets up delegation for common methods such as `import` and `search`.
    #
    # @example Include the module in the `Article` model definition
    #
    #     class Article < ActiveRecord::Base
    #       include OpenSearch::Model
    #     end
    #
    # @example Inject the module into the `Article` model during run time
    #
    #     Article.__send__ :include, OpenSearch::Model
    #
    #
    def self.included(base)
      base.class_eval do
        include OpenSearch::Model::Proxy

        # Delegate common methods to the `__opensearch__` ClassMethodsProxy, unless they are defined already
        class << self
          METHODS.each do |method|
            delegate method, to: :__opensearch__ unless self.public_instance_methods.include?(method)
          end
        end
      end

      # Add to the model to the registry if it's a class (and not in intermediate module)
      Registry.add(base) if base.is_a?(Class)
    end

    module ClassMethods
      # Get the client common for all models
      #
      # @example Get the client
      #
      #     OpenSearch::Model.client
      #     => #<OpenSearch::Client:0x007f96a7d0d000... >
      #
      def client
        @client ||= OpenSearch::Client.new
      end

      # Set the client for all models
      #
      # @example Configure (set) the client for all models
      #
      #     OpenSearch::Model.client = OpenSearch::Client.new host: 'http://localhost:9200', tracer: true
      #     => #<OpenSearch::Client:0x007f96a6dd0d80... >
      #
      # @note You have to set the client before you call OpenSearch methods on the model,
      #       or set it directly on the model; see {OpenSearch::Model::Client::ClassMethods#client}
      #
      def client=(client)
        @client = client
      end

      # Search across multiple models
      #
      # By default, all models which include the `OpenSearch::Model` module are searched
      #
      # @param query_or_payload [String,Hash,Object] The search request definition
      #                                              (string, JSON, Hash, or object responding to `to_hash`)
      # @param models [Array] The Array of Model objects to search
      # @param options [Hash] Optional parameters to be passed to the OpenSearch client
      #
      # @return [OpenSearch::Model::Response::Response]
      #
      # @example Search across specific models
      #
      #     OpenSearch::Model.search('foo', [Author, Article])
      #
      # @example Search across all models which include the `OpenSearch::Model` module
      #
      #     OpenSearch::Model.search('foo')
      #
      def search(query_or_payload, models=[], options={})
        models = Multimodel.new(models)
        request = Searching::SearchRequest.new(models, query_or_payload, options)
        Response::Response.new(models, request)
      end

      # Access the module settings
      #
      def settings
        @settings ||= {}
      end
    end
    extend ClassMethods

    class NotImplemented < NoMethodError; end
  end
end
