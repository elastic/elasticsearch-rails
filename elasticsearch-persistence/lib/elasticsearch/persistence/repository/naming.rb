module Elasticsearch
  module Persistence
    module Repository

      # Wraps all naming-related features of the repository (index name, the domain object class, etc)
      #
      module Naming

        # The possible keys for a document id.
        #
        IDS = [:id, 'id', :_id, '_id'].freeze

        DEFAULT_DOC_TYPE = '_doc'.freeze

        # Get or set the class used to initialize domain objects when deserializing them
        #
        def klass(name=nil)
          if name
            @klass = name
          else
            @klass
          end
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
          @document_type = name || @document_type || DEFAULT_DOC_TYPE
        end; alias :type :document_type

        # Set the document type used when storing and retrieving documents
        #
        def document_type=(name)
          @document_type = name
        end; alias :type= :document_type=

        # Get a document ID from the document (assuming Hash or Hash-like object)
        #
        # @example
        #     repository.__get_id_from_document title: 'Test', id: 'abc123'
        #     => "abc123"
        #
        # @api private
        #
        def __get_id_from_document(document)
          document[IDS.find { |id| document[id] }]
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
          IDS.inject(nil) do |deleted, id|
            if document[id]
              document.delete(id)
            else
              deleted
            end
          end
        end
      end

    end
  end
end
