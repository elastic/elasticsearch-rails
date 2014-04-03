module Elasticsearch
  module Model
    module Response

      # Encapsulates the "hit" returned from the Elasticsearch client
      #
      # Wraps the raw Hash with in a `Hashie::Mash` instance, providing
      # access to the Hash properties by calling Ruby methods.
      #
      # @see https://github.com/intridea/hashie
      #
      class Result

        # @param attributes [Hash] A Hash with document properties
        #
        def initialize(attributes={})
          @result = Hashie::Mash.new(attributes)
        end

        # Delegate methods to `@result` or `@result._source`
        #
        def method_missing(method_name, *arguments)
          case
          when method_name.to_s.end_with?('?')
            delegate_to_source(method_name, *arguments)
          when @result.respond_to?(method_name)
            @result.__send__ method_name, *arguments
          when @result._source && @result._source.respond_to?(method_name)
            delegate_to_source(method_name, *arguments)
          else
            super
          end
        end

        # Respond to methods from `@result` or `@result._source`
        #
        def respond_to?(method_name, include_private = false)
          @result.respond_to?(method_name.to_sym) || \
          @result._source && @result._source.respond_to?(method_name.to_sym) || \
          super
        end

        def as_json(options={})
          @result.as_json(options)
        end

        # TODO: #to_s, #inspect, with support for Pry

        private

        def delegate_to_source(method, *args)
          @result._source.__send__ method, *args
        end

      end
    end
  end
end
