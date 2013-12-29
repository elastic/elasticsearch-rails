module Elasticsearch
  module Model
    module Response
      # Common funtionality for classes in the {Elasticsearch::Model::Response} module
      #
      module Base
        attr_reader :klass, :response

        # @param klass    [Class] The name of the model class
        # @param response [Hash]  The full response returned from Elasticsearch client
        # @param results  [Results]  The collection of results
        #
        def initialize(klass, response, options={})
          @klass     = klass
          @response  = response
        end

        # @abstract Implement this method in specific class
        #
        def results
          raise NotImplemented, "Implement this method in #{klass}"
        end

        # @abstract Implement this method in specific class
        #
        def records
          raise NotImplemented, "Implement this method in #{klass}"
        end

        # Returns the total number of hits
        #
        def total
          response.response['hits']['total']
        end

        # Returns the max_score
        #
        def max_score
          response.response['hits']['max_score']
        end
      end
    end
  end
end
