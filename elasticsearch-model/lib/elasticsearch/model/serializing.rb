module Elasticsearch
  module Model
    module Serializing

      module ClassMethods
      end

      module InstanceMethods

        # Serialize the record as Hash
        #
        def as_indexed_json(options={})
          # TODO: Play with the `MyModel.indexes` method -- reject non-mapped attributes, `:as` options, etc
          self.as_json(options)
        end

      end

    end
  end
end
