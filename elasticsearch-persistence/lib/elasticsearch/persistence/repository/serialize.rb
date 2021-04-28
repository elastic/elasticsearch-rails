# Licensed to Elasticsearch B.V. under one or more contributor
# license agreements. See the NOTICE file distributed with
# this work for additional information regarding copyright
# ownership. Elasticsearch B.V. licenses this file to you under
# the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
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

      # Provide serialization and deserialization between Ruby objects and Elasticsearch documents.
      #
      # Override these methods in your repository class to customize the logic.
      #
      module Serialize

        # Serialize the object for storing it in Elasticsearch.
        #
        # In the default implementation, call the `to_hash` method on the passed object.
        #
        # @param [ Object ] document The Ruby object to serialize.
        #
        # @return [ Hash ] The serialized document.
        #
        def serialize(document)
          document.to_hash
        end

        # Deserialize the document retrieved from Elasticsearch into a Ruby object.
        # If no klass is set for the Repository then the raw document '_source' field will be returned.
        #
        # def deserialize(document)
        #   Note.new document[SOURCE]
        # end
        #
        # @param [ Hash ] document The raw document.
        #
        # @return [ Object ] The deserialized object.
        #
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
