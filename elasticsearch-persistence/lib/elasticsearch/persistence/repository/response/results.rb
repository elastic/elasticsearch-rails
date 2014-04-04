module Elasticsearch
  module Persistence
    module Repository
      module Response # :nodoc:

        # Encapsulates the domain objects and documents returned from Elasticsearch when searching
        #
        # Implements `Enumerable` and forwards its methods to the {#results} object.
        #
        class Results
          include Enumerable

          attr_reader :repository

          # @param repository [Elasticsearch::Persistence::Repository::Class] The repository instance
          # @param response   [Hash]  The full response returned from the Elasticsearch client
          # @param options    [Hash]  Optional parameters
          #
          def initialize(repository, response, options={})
            @repository = repository
            @response   = Hashie::Mash.new(response)
            @options    = options
          end

          def method_missing(method_name, *arguments, &block)
            results.respond_to?(method_name) ? results.__send__(method_name, *arguments, &block) : super
          end

          def respond_to?(method_name, include_private = false)
            results.respond_to?(method_name) || super
          end

          # The number of total hits for a query
          #
          def total
            response['hits']['total']
          end

          # The maximum score for a query
          #
          def max_score
            response['hits']['max_score']
          end

          # Yields [object, hit] pairs to the block
          #
          def each_with_hit(&block)
            results.zip(response['hits']['hits']).each(&block)
          end

          # Yields [object, hit] pairs and returns the result
          #
          def map_with_hit(&block)
            results.zip(response['hits']['hits']).map(&block)
          end

          # Return the collection of domain objects
          #
          # @example Iterate over the results
          #
          #     results.map { |r| r.attributes[:title] }
          #     => ["Fox", "Dog"]
          #
          # @return [Array]
          #
          def results
            @results ||= response['hits']['hits'].map do |document|
              repository.deserialize(document.to_hash)
            end
          end

          # Access the response returned from Elasticsearch by the client
          #
          # @example Access the aggregations in the response
          #
          #     results = repository.search query: { match: { title: 'fox dog' } },
          #                                 aggregations: { titles: { terms: { field: 'title' } } }
          #     results.response.aggregations.titles.buckets.map { |term| "#{term['key']}: #{term['doc_count']}" }
          #     # => ["brown: 1", "dog: 1", ...]
          #
          # @return [Hashie::Mash]
          #
          def response
            @response
          end
        end
      end
    end
  end
end
