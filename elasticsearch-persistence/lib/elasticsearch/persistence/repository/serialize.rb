module Elasticsearch
  module Persistence
    module Repository

      # Provide serialization and deserialization between Ruby objects and Elasticsearch documents
      #
      # Override these methods in your repository class to customize the logic.
      #
      module Serialize

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
          _klass = klass || __get_klass_from_type(document['_type'])
          _klass.new document['_source']
        end
      end

    end
  end
end
