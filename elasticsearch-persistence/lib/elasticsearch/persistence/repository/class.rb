module Elasticsearch
  module Persistence
    module Repository

      class Class
        include Elasticsearch::Persistence::Client
        include Elasticsearch::Persistence::Repository::Naming
        include Elasticsearch::Persistence::Repository::Serialize
        include Elasticsearch::Persistence::Repository::Store
        include Elasticsearch::Persistence::Repository::Find
        include Elasticsearch::Persistence::Repository::Search

        include Elasticsearch::Model::Indexing::ClassMethods

        attr_reader :options

        def initialize(options={}, &block)
          @options = options
          block.arity < 1 ? instance_eval(&block) : block.call(self) if block_given?
        end

        def host
          options[:host]
        end
      end

    end
  end
end
