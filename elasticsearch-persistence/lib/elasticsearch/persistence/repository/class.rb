module Elasticsearch
  module Persistence
    module Repository

      # The default repository class, to be used either directly, or as a gateway in a custom repository class
      #
      # @example Standalone use
      #
      #     repository = Elasticsearch::Persistence::Repository::Class.new
      #     # => #<Elasticsearch::Persistence::Repository::Class ...>
      #     # > repository.save(my_object)
      #     # => {"_index"=> ... }
      #
      #
      # @example Shortcut use
      #
      #     repository = Elasticsearch::Persistence::Repository.new
      #     # => #<Elasticsearch::Persistence::Repository::Class ...>
      #
      # @example Configuration via a block
      #
      #     repository = Elasticsearch::Persistence::Repository.new do
      #       index 'my_notes'
      #     end
      #     # => #<Elasticsearch::Persistence::Repository::Class ...>
      #     # > repository.save(my_object)
      #     # => {"_index"=> ... }
      #
      # @example Accessing the gateway in a custom class
      #
      #     class MyRepository
      #       include Elasticsearch::Persistence::Repository
      #     end
      #
      #     repository = MyRepository.new
      #
      #     repository.gateway.client.info
      #     => {"status"=>200, "name"=>"Venom", ... }
      #
      class Class
        include Elasticsearch::Persistence::Repository::Client
        include Elasticsearch::Persistence::Repository::Naming
        include Elasticsearch::Persistence::Repository::Serialize
        include Elasticsearch::Persistence::Repository::Store
        include Elasticsearch::Persistence::Repository::Find
        include Elasticsearch::Persistence::Repository::Search

        include Elasticsearch::Model::Indexing::ClassMethods

        attr_reader :options

        def initialize(options={}, &block)
          @options = options
          index_name options.delete(:index)
          block.arity < 1 ? instance_eval(&block) : block.call(self) if block_given?
        end

        # Return the "host" class, if this repository is a gateway hosted in another class
        #
        # @return [nil, Class]
        #
        def host
          options[:host]
        end
      end

    end
  end
end
