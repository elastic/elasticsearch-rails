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
  module Persistence
    module Repository

      # Returns a collection of domain objects by an Elasticsearch query
      #
      module Search

        # Returns a collection of domain objects by an Elasticsearch query
        #
        # Pass the query either as a string or a Hash-like object
        #
        # @example Return objects matching a simple query
        #
        #     repository.search('fox or dog')
        #
        # @example Return objects matching a query in the Elasticsearch DSL
        #
        #    repository.search(query: { match: { title: 'fox dog' } })
        #
        # @example Define additional search parameters, such as highlighted excerpts
        #
        #    results = repository.search(query: { match: { title: 'fox dog' } }, highlight: { fields: { title: {} } })
        #     results.map_with_hit { |d,h| h.highlight.title.join }
        #     # => ["quick brown <em>fox</em>", "fast white <em>dog</em>"]
        #
        # @example Perform aggregations as part of the request
        #
        #     results = repository.search query: { match: { title: 'fox dog' } },
        #                                 aggregations: { titles: { terms: { field: 'title' } } }
        #     results.response.aggregations.titles.buckets.map { |term| "#{term['key']}: #{term['doc_count']}" }
        #     # => ["brown: 1", "dog: 1", ... ]
        #
        # @example Pass additional options to the search request, such as `size`
        #
        #     repository.search query: { match: { title: 'fox dog' } }, size: 25
        #     # GET http://localhost:9200/notes/note/_search
        #     # > {"query":{"match":{"title":"fox dog"}},"size":25}
        #
        # @param [ Hash, String ] query_or_definition The query or search definition.
        # @param [ Hash ] options The search options.
        #
        # @return [Elasticsearch::Persistence::Repository::Response::Results]
        #
        def search(query_or_definition, options={})
          request = { index: index_name,
                      type: document_type }
          if query_or_definition.respond_to?(:to_hash)
            request[:body] = query_or_definition.to_hash
          elsif query_or_definition.is_a?(String)
            request[:q] = query_or_definition
          else
            raise ArgumentError, "[!] Pass the search definition as a Hash-like object or pass the query as a String" +
              " -- #{query_or_definition.class} given."
          end

          Response::Results.new(self, client.search(request.merge(options)))
        end

        # Return the number of domain object in the index
        #
        # @example Return the number of all domain objects
        #
        #     repository.count
        #     # => 2
        #
        # @example Return the count of domain object matching a simple query
        #
        #     repository.count('fox or dog')
        #     # => 1
        #
        # @example Return the count of domain object matching a query in the Elasticsearch DSL
        #
        #    repository.count(query: { match: { title: 'fox dog' } })
        #    # => 1
        #
        # @param [ Hash, String ] query_or_definition The query or search definition.
        # @param [ Hash ] options The search options.
        #
        # @return [Integer]
        #
        def count(query_or_definition=nil, options={})
          query_or_definition ||= { query: { match_all: {} } }
          request = { index: index_name,
                      type: document_type }

          if query_or_definition.respond_to?(:to_hash)
            request[:body] = query_or_definition.to_hash
          elsif query_or_definition.is_a?(String)
            request[:q] = query_or_definition
          else
            raise ArgumentError, "[!] Pass the search definition as a Hash-like object or pass the query as a String" +
                " -- #{query_or_definition.class} given."
          end

          client.count(request.merge(options))[COUNT]
        end

        private

        # The key for accessing the count in a Elasticsearch query response.
        #
        COUNT = 'count'.freeze
      end
    end
  end
end
