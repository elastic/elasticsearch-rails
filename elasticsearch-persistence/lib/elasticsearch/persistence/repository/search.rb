module Elasticsearch
  module Persistence
    module Repository

      # Returns a collection of domain objects by an Elasticsearch query
      #
      module Search

        # The key for accessing the count in a Elasticsearch query response.
        #
        COUNT = 'count'.freeze

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
        # @return [Elasticsearch::Persistence::Repository::Response::Results]
        #
        def search(query_or_definition, options={})
          type = document_type

          case
          when query_or_definition.respond_to?(:to_hash)
            response = client.search( { index: index_name, type: type, body: query_or_definition.to_hash }.merge(options) )
          when query_or_definition.is_a?(String)
            response = client.search( { index: index_name, type: type, q: query_or_definition }.merge(options) )
          else
            raise ArgumentError, "[!] Pass the search definition as a Hash-like object or pass the query as a String" +
                                 " -- #{query_or_definition.class} given."
          end
          Response::Results.new(self, response)
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
        #    repository.search(query: { match: { title: 'fox dog' } })
        #    # => 1
        #
        # @return [Integer]
        #
        def count(query_or_definition=nil, options={})
          query_or_definition ||= { query: { match_all: {} } }
          type = document_type

          case
          when query_or_definition.respond_to?(:to_hash)
            response = client.count( { index: index_name, type: type, body: query_or_definition.to_hash }.merge(options) )
          when query_or_definition.is_a?(String)
            response = client.count( { index: index_name, type: type, q: query_or_definition }.merge(options) )
          else
            raise ArgumentError, "[!] Pass the search definition as a Hash-like object or pass the query as a String, not as [#{query_or_definition.class}]"
          end

          response[COUNT]
        end
      end

    end
  end
end
