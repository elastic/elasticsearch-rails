module Elasticsearch
  module Model
    module Adapter
      def from_class(klass)
        Adapter.new(klass)
      end; module_function :from_class

      class Adapter
        attr_reader :klass

        def initialize(klass)
          @klass = klass
        end

        def self.register(name, condition)
          self.adapters[name] = condition
        end

        def self.adapters
          @adapters ||= {}
        end

        def records_mixin
          adapter.const_get(:Records)
        end

        def callbacks_mixin
          adapter.const_get(:Callbacks)
        end

        def importing_mixin
          adapter.const_get(:Importing)
        end

        def adapter
          @adapter ||= begin
            self.class.adapters.find( lambda {[]} ) { |name, condition| condition.call(klass) }.first \
            || Elasticsearch::Model::Adapter::Default
          end
        end

      end
    end
  end
end
