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
        # @return {Hash} The response from Elasticsearch
        #
        def save(document, options={})
          serialized = serialize(document)
          id   = __get_id_from_document(serialized)
          type = document_type
          client.index( { index: index_name, type: type, id: id, body: serialized }.merge(options) )
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
        # @return {Hash} The response from Elasticsearch
        #
        def update(document, options={})
          case
            when document.is_a?(String) || document.is_a?(Integer)
              id = document
            when document.respond_to?(:to_hash)
              serialized = document.to_hash
              id = __extract_id_from_document(serialized)
            else
              raise ArgumentError, "Expected a document ID or a Hash-like object, #{document.class} given"
          end

          type = options.delete(:type) || \
                 (defined?(serialized) && serialized && serialized.delete(:type)) || \
                 document_type

          if defined?(serialized) && serialized
            body = if serialized[:script]
                       serialized.select { |k, v| [:script, :params, :upsert].include? k }
                     else
                       { doc: serialized }
                   end
          else
            body = {}
            body.update( doc: options.delete(:doc)) if options[:doc]
            body.update( script: options.delete(:script)) if options[:script]
            body.update( params: options.delete(:params)) if options[:params]
            body.update( upsert: options.delete(:upsert)) if options[:upsert]
          end

          client.update( { index: index_name, type: type, id: id, body: body }.merge(options) )
        end

        # Remove the serialized object or document with specified ID from Elasticsearch
        #
        # @example Remove the document with ID 1
        #
        #     repository.delete(1)
        #     # => {"_index"=>"...", "_type"=>"...", "_id"=>"1", "_version"=>4}
        #
        # @return {Hash} The response from Elasticsearch
        #
        def delete(document, options={})
          if document.is_a?(String) || document.is_a?(Integer)
            id   = document
            type = document_type
          else
            serialized = serialize(document)
            id   = __get_id_from_document(serialized)
            type = document_type
          end
          client.delete( { index: index_name, type: type, id: id }.merge(options) )
        end
      end

    end
  end
end
