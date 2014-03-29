module Elasticsearch
  module Persistence
    module Repository

      module Serialize
        def serialize(document)
          document.to_hash
        end

        def deserialize(document)
          _klass = klass || __get_klass_from_type(document['_type'])
          _klass.new document['_source']
        end
      end

    end
  end
end
