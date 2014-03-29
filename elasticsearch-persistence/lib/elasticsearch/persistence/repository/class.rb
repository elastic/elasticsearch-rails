module Elasticsearch
  module Persistence
    module Repository

      class Class
        include Elasticsearch::Persistence::Repository

        attr_reader :options

        def initialize(options={}, &block)
          @options = options
          block.arity < 1 ? instance_eval(&block) : block.call(self) if block_given?
        end
      end

    end
  end
end
