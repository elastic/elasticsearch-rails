module Elasticsearch
  module Model
    module Response

      class Aggregations < HashWrapper
        disable_warnings if respond_to?(:disable_warnings)

        def initialize(attributes={})
          __redefine_enumerable_methods super(attributes)
        end

        # Fix the problem of Hashie::Mash returning unexpected values for `min` and `max` methods
        #
        # People can define names for aggregations such as `min` and `max`, but these
        # methods are defined in `Enumerable#min` and `Enumerable#max`
        #
        #     { foo: 'bar' }.min
        #     # => [:foo, "bar"]
        #
        # Therefore, any Hashie::Mash instance value has the `min` and `max`
        # methods redefined to return the real value
        #
        def __redefine_enumerable_methods(h)
          if h.respond_to?(:each_pair)
            h.each_pair { |k, v| v = __redefine_enumerable_methods(v) }
          end
          if h.is_a?(Hashie::Mash)
            class << h
              define_method(:min) { self[:min] }
              define_method(:max) { self[:max] }
            end
          end
        end
      end

    end
  end
end
