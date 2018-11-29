# Licensed to Elasticsearch B.V. under one or more contributor
# license agreements. See the NOTICE file distributed with
# this work for additional information regarding copyright
# ownership. Elasticsearch B.V. licenses this file to you under
# the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#	http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

module Elasticsearch
  module Persistence
    module Repository
      class DocumentNotFound < StandardError; end

      # Retrieves one or more domain objects from the repository
      #
      module Find

        # Retrieve a single object or multiple objects from Elasticsearch by ID or IDs
        #
        # @example Retrieve a single object by ID
        #
        #     repository.find(1)
        #     # => <Note ...>
        #
        # @example Retrieve multiple objects by IDs
        #
        #     repository.find(1, 2)
        #     # => [<Note ...>, <Note ...>
        #
        # @return [Object,Array]
        #
        def find(*args)
          options  = args.last.is_a?(Hash) ? args.pop : {}
          ids      = args

          if args.size == 1
            id = args.pop
            id.is_a?(Array) ? __find_many(id, options) : __find_one(id, options)
          else
            __find_many args, options
          end
        end

        # Return if object exists in the repository
        #
        # @example
        #
        #     repository.exists?(1)
        #     => true
        #
        # @param [ String, Integer ] id The id to search.
        # @param [ Hash ] options The options.
        #
        # @return [true, false]
        #
        def exists?(id, options={})
          request = { index: index_name, id: id }
          request[:type] = document_type if document_type
          client.exists(request.merge(options))
        end

        private

        # The key for accessing the document found and returned from an
        #   Elasticsearch _mget query.
        #
        DOCS = 'docs'.freeze

        # The key for the boolean value indicating whether a particular id
        #   has been successfully found in an Elasticsearch _mget query.
        #
        FOUND = 'found'.freeze

        # @api private
        #
        def __find_one(id, options={})
          request = { index: index_name, id: id }
          request[:type] = document_type if document_type
          document = client.get(request.merge(options))
          deserialize(document)
        rescue Elasticsearch::Transport::Transport::Errors::NotFound => e
          raise DocumentNotFound, e.message, caller
        end

        # @api private
        #
        def __find_many(ids, options={})
          request = { index: index_name, body: { ids: ids } }
          request[:type] = document_type if document_type
          documents = client.mget(request.merge(options))
          documents[DOCS].map do |document|
            deserialize(document) if document[FOUND]
          end
        end
      end
    end
  end
end
