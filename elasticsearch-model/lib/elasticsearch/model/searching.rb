module Elasticsearch
  module Model

    # Contains functionality related to searching.
    #
    module Searching

      module ClassMethods

        # Provide a `search` method for the model to easily search within an index/type
        # corresponding to the model settings.
        #
        # @param query_or_payload [String,Hash] Query, Hash or JSON payload to use as search definition
        # @param options          [Hash]        Optional parameters to be passed to the Elasticsearch client
        #
        # @return [Elasticsearch::Model::Response::Response]
        #
        # @example Simple search in `Article`
        #
        #     Article.search 'foo'
        #
        # @example Search using a search definition as a Hash
        #
        #     response = Article.search \
        #                  query: {
        #                    match: {
        #                      title: 'foo'
        #                    }
        #                  },
        #                  highlight: {
        #                    fields: {
        #                      title: {}
        #                    }
        #                  }
        #
        #     response.results.first.title
        #     # => "Foo"
        #
        #     response.results.first.highlight.title
        #     # => ["<em>Foo</em>"]
        #
        #     response.records.first.title
        #     #  Article Load (0.2ms)  SELECT "articles".* FROM "articles" WHERE "articles"."id" IN (1, 3)
        #     # => "Foo"
        #
        # @example Search using a search definition as a JSON string
        #
        #     Article.search '{"query" : { "match_all" : {} }}'
        #
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
