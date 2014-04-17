module Elasticsearch
  module Model
    module Response

      # Encapsulates the "hit" returned from the Elasticsearch client
      #
      # Wraps the _source and highlight values in a `Hashie::Mash` instance,
      # providing access to those properties by calling Ruby methods.
      #
      # @see https://github.com/intridea/hashie
      #
      class Result
        attr_reader :attributes

        # @param attributes [Hash] A Hash with document properties
        #
        def initialize(attributes={})
          @attributes = attributes
        end

        def _source
          @_source ||= (Hashie::Mash.new(@attributes['_source']) if @attributes['_source'])
        end

        def _source?
          !!_source
        end

        def highlight
          @highlight ||= (Hashie::Mash.new(@attributes['highlight']) if @attributes['highlight'])
        end

        def highlight?
          !!highlight
        end

        # Delegate methods to `@attributes` or `self._source`
        #
        def method_missing(method_name, *arguments)
          if @attributes[method_name.to_s]
            @attributes[method_name.to_s]
          elsif _source.respond_to?(method_name)
            _source.send(method_name, *arguments)
          else
            super
          end
        end

        # Respond to `@attributes` or `self._source`
        #
        def respond_to?(method_name, include_private = false)
          @attributes[method_name.to_s] ||
          _source.respond_to?(method_name) ||
          super
        end

        def as_json(options={})
          @attributes.as_json(options)
        end

        def to_s
          to_json
        end

        alias_method :inspect, :to_s
      end
    end
  end
end
