module Elasticsearch
  module Model
    module Response
      class Records
        include Base

        def initialize(klass, response)
          super
          @ids = response['hits']['hits'].map { |hit| hit['_id'] }
        end

        def records
          @records = klass.find(@ids)
        end

        # Delegate methods to `@records`
        #
        def method_missing(method_name, *arguments)
          records.respond_to?(method_name) ? records.__send__(method_name, *arguments) : super
        end

        # Respond to methods from `@records`
        #
        def respond_to?(method_name, include_private = false)
          records.respond_to?(method_name) || super
        end

      end
    end
  end
end
