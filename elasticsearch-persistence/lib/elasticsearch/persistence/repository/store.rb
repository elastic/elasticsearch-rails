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

      # Save and delete documents in Elasticsearch
      #
      module Store

        # Store the serialized object in Elasticsearch
        #
        # @example
        #     repository.save(myobject)
        #     => {"_index"=>"...", "_type"=>"...", "_id"=>"...", "_version"=>1, "created"=>true}
        #
        # @param [ Object ] document The document to save into Elasticsearch.
        # @param [ Hash ] options The save request options.
        #
        # @return [ Hash ] The response from Elasticsearch
        #
        def save(document, options={})
          serialized = serialize(document)
          id = __get_id_from_document(serialized)
          request = { index: index_name,
                      id: id,
                      body: serialized }
          request[:type] = document_type if document_type
          client.index(request.merge(options))
        end

        # Update the serialized object in Elasticsearch with partial data or script
        #
        # @example Update the document with partial data
        #
        #     repository.update id: 1, title: 'UPDATED',  tags: []
        #     # => {"_index"=>"...", "_type"=>"...", "_id"=>"1", "_version"=>2}
        #
        # @example Update the document with a script
        #
        #     repository.update 1, script: 'ctx._source.views += 1'
        #     # => {"_index"=>"...", "_type"=>"...", "_id"=>"1", "_version"=>3}
        #
        # @param [ Object ] document_or_id The document to update or the id of the document to update.
        # @param [ Hash ] options The update request options.
        #
        # @return [ Hash ] The response from Elasticsearch
        #
        def update(document_or_id, options = {})
          if document_or_id.is_a?(String) || document_or_id.is_a?(Integer)
            id = document_or_id
            body = options
            type = document_type
          else
            document = serialize(document_or_id)
            id = __extract_id_from_document(document)
            if options[:script]
              body = options
            else
              body = { doc: document }.merge(options)
            end
            type = document.delete(:type) || document_type
          end
          client.update(index: index_name, id: id, type: type, body: body)
        end

        # Remove the serialized object or document with specified ID from Elasticsearch
        #
        # @example Remove the document with ID 1
        #
        #     repository.delete(1)
        #     # => {"_index"=>"...", "_type"=>"...", "_id"=>"1", "_version"=>4}
        #
        # @param [ Object ] document_or_id The document to delete or the id of the document to delete.
        # @param [ Hash ] options The delete request options.
        #
        # @return [ Hash ] The response from Elasticsearch
        #
        def delete(document_or_id, options = {})
          if document_or_id.is_a?(String) || document_or_id.is_a?(Integer)
            id = document_or_id
          else
            serialized = serialize(document_or_id)
            id = __get_id_from_document(serialized)
          end
          client.delete({ index: index_name, type: document_type, id: id }.merge(options))
        end
      end
    end
  end
end
