module Elasticsearch
  module Persistence
    module Repository

      module Search
        def search(query_or_definition, options={})
          type     = (klass ? __get_type_from_class(klass) : nil  )
          case
          when query_or_definition.respond_to?(:to_hash)
            response = client.search( { index: 'test', type: type, body: query_or_definition.to_hash }.merge(options) )
          when query_or_definition.is_a?(String)
            response = client.search( { index: 'test', type: type, q: query_or_definition }.merge(options) )
          else
            raise ArgumentError, "[!] Pass the search definition as a Hash-like object or pass the query as a String" +
                                 " -- #{query_or_definition.class} given."
          end
          Response::Results.new(self, response)
        end
      end

    end
  end
end
