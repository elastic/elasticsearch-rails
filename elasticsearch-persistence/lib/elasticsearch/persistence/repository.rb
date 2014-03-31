module Elasticsearch
  module Persistence

    module Repository
      include Elasticsearch::Persistence::Client
      include Elasticsearch::Persistence::Repository::Naming
      include Elasticsearch::Persistence::Repository::Serialize
      include Elasticsearch::Persistence::Repository::Store
      include Elasticsearch::Persistence::Repository::Find

      def new(options={}, &block)
        Elasticsearch::Persistence::Repository::Class.new options, &block
      end; module_function :new
    end
  end
end
