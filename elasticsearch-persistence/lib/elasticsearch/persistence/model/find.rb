module Elasticsearch
  module Persistence
    module Model

      module Find
        module ClassMethods

          # Returns all models (up to 10,000)
          #
          # @example Retrieve all people
          #
          #     Person.all
          #     # => [#<Person:0x007ff1d8fb04b0 ... ]
          #
          # @example Retrieve all people matching a query
          #
          #     Person.all query: { match: { last_name: 'Smith'  } }
          #     # => [#<Person:0x007ff1d8fb04b0 ... ]
          #
          def all(options={})
            gateway.search( { query: { match_all: {} }, size: 10_000 }.merge(options) )
          end

          # Returns all models efficiently via the Elasticsearch's scan/scroll API
          #
          # You can restrict the models being returned with a query.
          #
          # The full {Persistence::Repository::Response::Result} instance is yielded to the passed
          # block in each batch, so you can access any of its properties. Calling `to_a` will
          # convert the object to an Array of model instances.
          #
          # @example Return all models in batches of 20 x number of primary shards
          #
          #     Person.find_in_batches { |batch| puts batch.map(&:name) }
          #
          # @example Return all models in batches of 100 x number of primary shards
          #
          #     Person.find_in_batches(size: 100) { |batch| puts batch.map(&:name) }
          #
          # @example Return all models matching a specific query
          #
          #      Person.find_in_batches(query: { match: { name: 'test' } }) { |batch| puts batch.map(&:name) }
          #
          # @example Return all models, fetching only the `name` attribute from Elasticsearch
          #
          #      Person.find_in_batches( _source_include: 'name') { |_| puts _.response.hits.hits.map(&:to_hash) }
          #
          # @example Leave out the block to return an Enumerator instance
          #
          #      Person.find_in_batches(size: 100).map { |batch| batch.size }
          #      # => [100, 100, 100, ... ]
          #
          # @return [String,Enumerator] The `scroll_id` for the request or Enumerator when the block is not passed
          #
          def find_in_batches(options={}, &block)
            return to_enum(:find_in_batches, options) unless block_given?

            search_params = options.extract!(
              :index,
              :type,
              :scroll,
              :size,
              :explain,
              :ignore_indices,
              :ignore_unavailable,
              :allow_no_indices,
              :expand_wildcards,
              :preference,
              :q,
              :routing,
              :source,
              :_source,
              :_source_include,
              :_source_exclude,
              :stats,
              :timeout)

            scroll = search_params.delete(:scroll) || '5m'

            body = options

            # Get the initial scroll_id
            #
            response = gateway.client.search( { index: gateway.index_name,
                                         type:  gateway.document_type,
                                         search_type: 'scan',
                                         scroll:      scroll,
                                         size:        20,
                                         body:        body }.merge(search_params) )

            # Get the initial batch of documents
            #
            response = gateway.client.scroll( { scroll_id: response['_scroll_id'], scroll: scroll } )

            # Break when receiving an empty array of hits
            #
            while response['hits']['hits'].any? do
              yield Repository::Response::Results.new(gateway, response)

              response = gateway.client.scroll( { scroll_id: response['_scroll_id'], scroll: scroll } )
            end

            return response['_scroll_id']
          end
        end
      end

    end
  end
end
