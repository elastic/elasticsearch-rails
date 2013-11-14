module Elasticsearch
  module Model
    module Response
      module Base
        attr_reader :klass, :response

        def initialize(klass, response, results=nil)
          @klass     = klass
          @response  = response
          @total     = response['total']
          @max_score = response['max_score']
        end

        def results
          raise NoMethodError, "Abstract method called"
        end

        def records
          raise NoMethodError, "Abstract method called"
        end

      end
    end
  end
end
