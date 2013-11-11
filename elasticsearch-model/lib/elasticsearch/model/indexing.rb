module Elasticsearch
  module Model
    module Indexing

      module ClassMethods
      end

      module InstanceMethods

        def index_document(options={})
          document = self.as_indexed_json

          client.index(
            { index: index_name,
              type:  document_type,
              id:    self.id,
              body:  document }.merge(options)
          )
        end

        def delete_document(options={})
          client.delete(
            { index: index_name,
              type:  document_type,
              id:    self.id }.merge(options)
          )
        end

        def update_document(options={})
          # TODO: Intercept changes to the record, and use `changed_attributes`
          #       to perform update by partial doc.
          index_document(options)
        end

      end

    end
  end
end
