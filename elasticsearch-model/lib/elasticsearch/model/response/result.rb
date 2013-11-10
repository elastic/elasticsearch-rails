module Elasticsearch
  module Model
    module Response
      class Result

        def initialize(attributes)
          @result = Hashie::Mash.new(attributes)
        end

        # Delegate methods to `@result`
        #
        def method_missing(method_name, *arguments)
          case
          when @result.respond_to?(method_name.to_sym)
            @result[method_name.to_sym]
          when @result._source && @result._source.respond_to?(method_name.to_sym)
            @result._source[method_name.to_sym]
          else
            super
          end
        end

        # Respond to methods from `@result`
        #
        def respond_to?(method_name, include_private = false)
          @result.has_key?(method_name.to_sym) || \
          @result._source && @result._source.has_key?(method_name.to_sym) || \
          super
        end

        # TODO: #to_s, #inspect, with support for Pry

      end
    end
  end
end
