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
      module Response # :nodoc:

        # Encapsulates the domain objects and documents returned from Elasticsearch when searching
        #
        # Implements `Enumerable` and forwards its methods to the {#results} object.
        #
        class Results
          include Enumerable

          attr_reader :repository
          attr_reader :raw_response

          # The key for accessing the results in an Elasticsearch query response.
          #
          HITS = 'hits'.freeze

          # The key for accessing the total number of hits in an Elasticsearch query response.
          #
          TOTAL = 'total'.freeze

          # The key for accessing the maximum score in an Elasticsearch query response.
          #
          MAX_SCORE = 'max_score'.freeze

          # @param repository [Elasticsearch::Persistence::Repository::Class] The repository instance
          # @param response   [Hash]  The full response returned from the Elasticsearch client
          # @param options    [Hash]  Optional parameters
          #
          def initialize(repository, response, options={})
            @repository = repository
            @raw_response = response
            @options = options
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
            raw_response[HITS][TOTAL]
          end

          # The maximum score for a query
          #
          def max_score
            raw_response[HITS][MAX_SCORE]
          end

          # Yields [object, hit] pairs to the block
          #
          def each_with_hit(&block)
            results.zip(raw_response[HITS][HITS]).each(&block)
          end

          # Yields [object, hit] pairs and returns the result
          #
          def map_with_hit(&block)
            results.zip(raw_response[HITS][HITS]).map(&block)
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
            @results ||= raw_response[HITS][HITS].map do |document|
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
          # @return [Elasticsearch::Model::HashWrapper]
          #
          def response
            @response ||= Elasticsearch::Model::HashWrapper.new(raw_response)
          end
        end
      end
    end
  end
end
