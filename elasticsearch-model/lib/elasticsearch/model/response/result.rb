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

        # Return document `_id` as `id`
        #
        def id
          @result['_id']
        end

        # Return document `_type` as `_type`
        #
        def type
          @result['_type']
        end

        # Delegate methods to `@result` or `@result._source`
        #
        def method_missing(name, *arguments)
          case
          when name.to_s.end_with?('?')
            @result.__send__(name, *arguments) || ( @result._source && @result._source.__send__(name, *arguments) )
          when @result.respond_to?(name)
            @result.__send__ name, *arguments
          when @result._source && @result._source.respond_to?(name)
            @result._source.__send__ name, *arguments
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
      end
    end
  end
end
