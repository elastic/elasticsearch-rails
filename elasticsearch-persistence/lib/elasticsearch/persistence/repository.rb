module Elasticsearch
  module Persistence

    module Repository
      include Elasticsearch::Persistence::Client

      def new(options={}, &block)
        Elasticsearch::Persistence::Repository::Class.new options, &block
      end; module_function :new
    end
  end
end
