module Elasticsearch
  module Persistence
    module Repository

      module Store
        def save(document, options={})
          serialized = serialize(document)
          id   = __get_id_from_document(serialized)
          type = __get_type_from_class(klass || document.class)
          client.index( { index: index_name, type: type, id: id, body: serialized }.merge(options) )
        end

        def delete(document, options={})
          if document.is_a?(String) || document.is_a?(Integer)
            id   = document
            type = __get_type_from_class(klass)
          else
            serialized = serialize(document)
            id   = __get_id_from_document(serialized)
            type = __get_type_from_class(klass || document.class)
          end
          client.delete( { index: index_name, type: type, id: id }.merge(options) )
        end
      end

    end
  end
end
