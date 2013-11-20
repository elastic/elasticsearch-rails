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
        def initialize(klass, response, results=nil)
          @klass     = klass
          @response  = response
          @total     = response['total']
          @max_score = response['max_score']
        end

        # @abstract Implement this method in specific class
        #
        def results
          raise NoMethodError, "Abstract method called"
        end

        # @abstract Implement this method in specific class
        #
        def records
          raise NoMethodError, "Abstract method called"
        end

      end
    end
  end
end
