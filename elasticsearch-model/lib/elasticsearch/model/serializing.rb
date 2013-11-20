module Elasticsearch
  module Model

    # Contains functionality for serializing model instances for the client
    #
    module Serializing

      module ClassMethods
      end

      module InstanceMethods

        # Serialize the record as a Hash, to be passed to the client.
        #
        # @return [Hash]
        #
        # @example
        #
        #     Article.first.__elasticsearch__.as_indexed_json(only: 'title')
        #     => {"title"=>"Foo"}
        #
        # @see Elasticsearch::Model::Indexing
        #
        def as_indexed_json(options={})
          # TODO: Play with the `MyModel.indexes` method -- reject non-mapped attributes, `:as` options, etc
          self.as_json(options)
        end

      end

    end
  end
end
