module Elasticsearch
  module Persistence
    module Repository
      module Response

        class Results
          include Enumerable

          attr_reader :repository, :response, :response

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

          def total
            response['hits']['total']
          end

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

          def results
            @results ||= response['hits']['hits'].map do |document|
              repository.deserialize(document.to_hash)
            end
          end
        end
      end
    end
  end
end
