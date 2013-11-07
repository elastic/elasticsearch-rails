module Elasticsearch
  module Model
    module Response
      class Records
        include Enumerable

        extend  Forwardable
        def_delegators :records, :each, :empty?, :size, :slice, :[], :to_a, :to_ary

        include Base

        def initialize(klass, response)
          super
          @ids = response['hits']['hits'].map { |hit| hit['_id'] }

          # Include module provided by the adapter in the singleton class ("metaclass")
          #
          adapter = Adapter.from_class(klass)
          metaclass = class << self; self; end
          metaclass.__send__ :include, adapter.records_mixin
          self
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
