module Elasticsearch
  module Persistence
    module Repository

      # Provide serialization and deserialization between Ruby objects and Elasticsearch documents
      #
      # Override these methods in your repository class to customize the logic.
      #
      module Serialize

        # Error message raised when documents are attempted to be deserialized and no klass is defined for
        #   the Repository.
        #
        # @since 6.0.0
        NO_CLASS_ERROR_MESSAGE = "No class is defined for deserializing documents. " +
                                   "Please define a 'klass' for the Repository or define a custom " +
                                   "deserialize method.".freeze

        # The key for document fields in an Elasticsearch query response.
        #
        SOURCE = '_source'.freeze

        # The key for the document type in an Elasticsearch query response.
        #   Note that it will be removed eventually, as multiple types in a single
        #   index are deprecated as of Elasticsearch 6.0.
        #
        TYPE = '_type'.freeze

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
        def deserialize(document)
          raise NameError.new(NO_CLASS_ERROR_MESSAGE) unless klass
          klass.new document[SOURCE]
        end
      end
    end
  end
end
