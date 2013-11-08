module Elasticsearch
  module Model
    module Searching

      module ClassMethods

        def search(query_or_payload, options={})
          response = client.search index: index_name, type: document_type, q: query_or_payload
          Response::Response.new(self, response)
        end

      end

    end
  end
end
