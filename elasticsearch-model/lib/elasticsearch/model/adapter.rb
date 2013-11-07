module Elasticsearch
  module Model
    module Adapter
      def from_class(klass)
        Adapter.new(klass)
      end
      module_function :from_class

      class Adapter

        def initialize(klass)
        end

        def response
          Elasticsearch::Model::Adapter::ActiveRecord::Records
        end

      end
    end
  end
end
