module Elasticsearch
  module Model
    module Response
      # Common funtionality for classes in the {Elasticsearch::Model::Response} module
      #
      module Base
        attr_reader :klass, :response, :response_object,
                    :total, :max_score

        # @param klass    [Class] The name of the model class
        # @param response [Hash]  The full response returned from Elasticsearch client
        # @param results  [Results]  The collection of results
        #
        def initialize(klass, response, results=nil, response_object=nil)
          @klass     = klass
          @response_object = response_object
          @response  = response
          @total     = response['hits']['total']
          @max_score = response['hits']['max_score']
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

      end
    end
  end
end
