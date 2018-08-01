module Elasticsearch
  module Persistence
    module Repository

      # Provide serialization and deserialization between Ruby objects and Elasticsearch documents
      #
      # Override these methods in your repository class to customize the logic.
      #
      module Serialize

        # Base methods for the class and single repository instance.
        #
        # @return [ Array<Symbol> ] The base methods.
        #
        # @since 6.0.0
        BASE_METHODS = [ :serialize,
                         :deserialize ].freeze

        def self.included(base)

          # Define each base method explicitly so that #method_missing does not have to be used
          #  each time the method is called.
          #
          BASE_METHODS.each do |_method|
            base.class_eval("def self.#{_method}(*args); instance.send(__method__, *args); end", __FILE__, __LINE__)
          end
        end

        # Serialize the object for storing it in Elasticsearch
        #
        # In the default implementation, call the `to_hash` method on the passed object.
        #
        def serialize(document)
          document.to_hash
        end

        # Deserialize the document retrieved from Elasticsearch into a Ruby object
        #
        # Use the `klass` property, if defined, otherwise try to get the class from the document's `_type`.
        #
        # def deserialize(document)
        #   raise NameError.new(NO_CLASS_ERROR_MESSAGE) unless klass
        #   klass.new document[SOURCE]
        # end
        def deserialize(document)
          klass ? klass.new(document[SOURCE]) : document[SOURCE]
        end

        private

        # The key for document fields in an Elasticsearch query response.
        #
        SOURCE = '_source'.freeze

        # The key for the document type in an Elasticsearch query response.
        #   Note that it will be removed eventually, as multiple types in a single
        #   index are deprecated as of Elasticsearch 6.0.
        #
        TYPE = '_type'.freeze

        IDS = [:id, 'id', :_id, '_id'].freeze

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
