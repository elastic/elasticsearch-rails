module Elasticsearch
  module Persistence
    module Repository

      module Naming
        def klass
          @klass
        end

        def klass=klass
          @klass = klass
        end

        def __get_klass_from_type(type)
          klass = type.classify
          klass.constantize
        rescue NameError => e
          raise NameError, "Attempted to get class '#{klass}' from the '#{type}' type, but no such class can be found."
        end

        def __get_type_from_class(klass)
          klass.to_s.underscore
        end

        def __get_id_from_document(document)
          document[:id] || document['id'] || document[:_id] || document['_id']
        end
      end

    end
  end
end
