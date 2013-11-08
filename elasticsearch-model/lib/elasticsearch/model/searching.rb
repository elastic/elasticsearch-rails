module Elasticsearch
  module Model
    module Searching

      module ClassMethods

        def search(query_or_payload, options={})
          __index_name    = options[:index] || index_name
          __document_type = options[:type]  || document_type

          case
            # search query: ...
            when query_or_payload.respond_to?(:to_hash)
              response = client.search index: __index_name, type: __document_type, body: query_or_payload.to_hash

            # search '{ "query" : ... }'
            when query_or_payload.is_a?(String) && query_or_payload =~ /^\s*{/
              response = client.search index: __index_name, type: __document_type, body: query_or_payload

            # search '...'
            else
              response = client.search index: __index_name, type: __document_type, q: query_or_payload
          end

          Response::Response.new(self, response)
        end

      end

    end
  end
end
