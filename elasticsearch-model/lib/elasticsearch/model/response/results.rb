module Elasticsearch
  module Model
    module Response

      # Encapsulates the collection of documents returned from Elasticsearch
      #
      # Implements Enumerable and forwards its methods to the {#results} object.
      #
      class Results
        include Base

        attr_reader :results

        include Enumerable

        extend  Support::Forwardable
        forward :results, :each, :empty?, :size, :slice, :[], :to_a, :to_ary

        # @see Base#initialize
        #
        def initialize(klass, response, results=nil, response_object=nil)
          super
          # TODO: Configurable custom wrapper
          @results   = response['hits']['hits'].map { |hit| Result.new(hit) }
        end

      end
    end
  end
end
