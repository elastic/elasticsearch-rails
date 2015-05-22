module Elasticsearch
  module Model
    module Response

      # Encapsulates the collection of documents returned from Elasticsearch
      #
      # Implements Enumerable and forwards its methods to the {#results} object.
      #
      class Results
        include Base
        include Enumerable

        delegate :each, :empty?, :size, :slice, :[], :to_a, :to_ary, to: :results

        # @see Base#initialize
        #
        def initialize(klass, response, options={})
          super
        end

        # Returns the {Results} collection
        #
        def results
          # TODO: Configurable custom wrapper
          response.response['hits']['hits'].map { |hit| Result.new(hit) }
        end

      end
    end
  end
end
