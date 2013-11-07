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

        def records_mixin
          adapter.const_get(:Records)
        end

        def adapter
          @adapter ||= case
            when defined?(::ActiveRecord::Base) && klass.ancestors.include?(::ActiveRecord::Base)
              Elasticsearch::Model::Adapter::ActiveRecord
            when defined?(::Mongoid) && klass.ancestors.include?(::Mongoid::Document)
              Elasticsearch::Model::Adapter::Mongoid
            else
              Elasticsearch::Model::Adapter::Default
          end
        end

      end
    end
  end
end
