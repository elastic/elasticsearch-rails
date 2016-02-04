module Elasticsearch
  module Persistence
    module Repository

      # Save and delete documents in Elasticsearch
      #
      module Store

        # Store the serialized object or objects in Elasticsearch
        #
        # @example
        #     repository.save(myobject)
        #     => {"_index"=>"...", "_type"=>"...", "_id"=>"...", "_version"=>1, "created"=>true}
        #
        # @example
        #     repository.save([myobject, myobject])
        #     => {"took"=>1, "errors"=>false, "items"=>[{"index"=>{"_index"=>"...", "_type"=>"...", "_id"=>"...", "status"=>200}}]}
        #
        # @return {Hash} The response from Elasticsearch
        #
        def save(document_or_documents, options={})
          if document_or_documents.is_a?(Array)
            __save_many(document_or_documents, options)
          else
            __save_one(document_or_documents, options)
          end
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
                 document_type || \
                 __get_type_from_class(klass)

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
            type = document_type || __get_type_from_class(klass)
          else
            serialized = serialize(document)
            id   = __get_id_from_document(serialized)
            type = document_type || __get_type_from_class(klass || document.class)
          end
          client.delete( { index: index_name, type: type, id: id }.merge(options) )
        end

        # Save one document using `client.index` method
        #
        # @api private
        #
        def __save_one(document, options={})
          document   = document.dup
          serialized = serialize(document)
          id   = __get_id_from_document(serialized)
          type = document_type || __get_type_from_class(klass || document.class)
          client.index( { index: index_name, type: type, id: id, body: serialized }.merge(options) )
        end

        # Save multiple documents using `client.bulk` method
        #
        # @api private
        #
        def __save_many(documents, options={})
          body = documents.map do |document|
            document   = document.dup
            payload    = {}
            serialized = serialize(document)
            id         = __get_id_from_document(serialized)
            type       = document_type || __get_type_from_class(klass || document.class)

            payload[:_id]    = id
            payload[:_type]  = type
            payload[:_index] = index_name

            [:_parent, :_version, :_routing].each do |attribute|
              if value = __extract_attribute_from_document(serialized, attribute)
                payload[attribute] = value
              end
            end

            payload[:data]  = serialized

            { index: payload.merge(options) }
          end

          client.bulk body: body
        end
      end
    end
  end
end
