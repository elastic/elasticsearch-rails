module Elasticsearch
  module Persistence
    module Repository

      # Wraps all naming-related features of the repository (index name, the domain object class, etc)
      #
      module Naming

        # Get or set the class used to initialize domain objects when deserializing them
        #
        def klass name=nil
          @klass = name || @klass
        end

        # Set the class used to initialize domain objects when deserializing them
        #
        def klass=klass
          @klass = klass
        end

        # Get or set the index name used when storing and retrieving documents
        #
        def index_name name=nil
          @index_name = name || @index_name || begin
            if respond_to?(:host) && host && host.is_a?(Module)
              self.host.to_s.underscore.gsub(/\//, '-')
            else
              self.class.to_s.underscore.gsub(/\//, '-')
            end
          end
        end; alias :index :index_name

        # Set the index name used when storing and retrieving documents
        #
        def index_name=(name)
          @index_name = name
        end; alias :index= :index_name=

        # Get or set the document type used when storing and retrieving documents
        #
        def document_type name=nil
          @document_type = name || @document_type || (klass ? klass.to_s.underscore : nil)
        end; alias :type :document_type

        # Set the document type used when storing and retrieving documents
        #
        def document_type=(name)
          @document_type = name
        end; alias :type= :document_type=

        # Get the Ruby class from the Elasticsearch `_type`
        #
        # @example
        #     repository.__get_klass_from_type 'note'
        #     => Note
        #
        # @return [Class] The class corresponding to the passed type
        # @raise [NameError] if the class cannot be found
        #
        # @api private
        #
        def __get_klass_from_type(type)
          klass = type.classify
          klass.constantize
        rescue NameError => e
          raise NameError, "Attempted to get class '#{klass}' from the '#{type}' type, but no such class can be found."
        end

        # Get the Elasticsearch `_type` from the Ruby class
        #
        # @example
        #     repository.__get_type_from_class Note
        #     => "note"
        #
        # @return [String] The type corresponding to the passed class
        #
        # @api private
        #
        def __get_type_from_class(klass)
          klass.to_s.underscore
        end

        # Get a document ID from the document (assuming Hash or Hash-like object)
        #
        # @example
        #     repository.__get_id_from_document title: 'Test', id: 'abc123'
        #     => "abc123"
        #
        # @api private
        #
        def __get_id_from_document(document)
          document[:id] || document['id'] || document[:_id] || document['_id']
        end

        # Extract a document ID from the document (assuming Hash or Hash-like object)
        #
        # @note Calling this method will *remove* the `id` or `_id` key from the passed object.
        #
        # @example
        #     options = { title: 'Test', id: 'abc123' }
        #     repository.__extract_id_from_document options
        #     # => "abc123"
        #     options
        #     # => { title: 'Test' }
        #
        # @api private
        #
        def __extract_id_from_document(document)
          document.delete(:id) || document.delete('id') || document.delete(:_id) || document.delete('_id')
        end

        # Extract an attribute from the document (assuming Hash or Hash-like object)
        #
        # @note Calling this method will *remove* the `attribute` key from the passed object.
        #
        # @example
        #     options = { title: 'Test', id: 'abc123', _parent: 'parent' }
        #     repository.__extract_attribute_from_document(options, :_parent)
        #     # => "parent"
        #     options
        #     # => { title: 'Test', id: 'abc123' }
        #
        # @api private
        #
        def __extract_attribute_from_document(document, attribute)
          document.delete(attribute.to_sym) || document.delete(attribute.to_s)
        end
      end

    end
  end
end
