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
  module Model

    # Contains functionality related to searching.
    #
    module Searching

      # Wraps a search request definition
      #
      class SearchRequest
        attr_reader :klass, :definition, :options

        # @param klass [Class] The class of the model
        # @param query_or_payload [String,Hash,Object] The search request definition
        #                                              (string, JSON, Hash, or object responding to `to_hash`)
        # @param options [Hash] Optional parameters to be passed to the Elasticsearch client
        #
        def initialize(klass, query_or_payload, options={})
          @klass   = klass
          @options = options

          __index_name    = options[:index] || klass.index_name
          __document_type = options[:type]  || klass.document_type

          case
            # search query: ...
            when query_or_payload.respond_to?(:to_hash)
              body = query_or_payload.to_hash

            # search '{ "query" : ... }'
            when query_or_payload.is_a?(String) && query_or_payload =~ /^\s*{/
              body = query_or_payload

            # search '...'
            else
              q = query_or_payload
          end

          if body
            @definition = { index: __index_name, type: __document_type, body: body }.update options
          else
            @definition = { index: __index_name, type: __document_type, q: q }.update options
          end
        end

        # Performs the request and returns the response from client
        #
        # @return [Hash] The response from Elasticsearch
        #
        def execute!
          klass.client.search(@definition)
        end
      end

      module ClassMethods

        # Provides a `search` method for the model to easily search within an index/type
        # corresponding to the model settings.
        #
        # @param query_or_payload [String,Hash,Object] The search request definition
        #                                              (string, JSON, Hash, or object responding to `to_hash`)
        # @param options [Hash] Optional parameters to be passed to the Elasticsearch client
        #
        # @return [Elasticsearch::Model::Response::Response]
        #
        # @example Simple search in `Article`
        #
        #     Article.search 'foo'
        #
        # @example Search using a search definition as a Hash
        #
        #     response = Article.search \
        #                  query: {
        #                    match: {
        #                      title: 'foo'
        #                    }
        #                  },
        #                  highlight: {
        #                    fields: {
        #                      title: {}
        #                    }
        #                  },
        #                  size: 50
        #
        #     response.results.first.title
        #     # => "Foo"
        #
        #     response.results.first.highlight.title
        #     # => ["<em>Foo</em>"]
        #
        #     response.records.first.title
        #     #  Article Load (0.2ms)  SELECT "articles".* FROM "articles" WHERE "articles"."id" IN (1, 3)
        #     # => "Foo"
        #
        # @example Search using a search definition as a JSON string
        #
        #     Article.search '{"query" : { "match_all" : {} }}'
        #
        def search(query_or_payload, options={})
          search   = SearchRequest.new(self, query_or_payload, options)

          Response::Response.new(self, search)
        end

      end

    end
  end
end
