module Elasticsearch
  module Persistence
    module Repository

      # Save and delete documents in Elasticsearch
      #
      module Store

        # Store the serialized object in Elasticsearch
        #
        def save(document, options={})
          serialized = serialize(document)
          id   = __get_id_from_document(serialized)
          type = document_type || __get_type_from_class(klass || document.class)
          client.index( { index: index_name, type: type, id: id, body: serialized }.merge(options) )
        end

        # Update the serialized object in Elasticsearch with partial data or script
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
      end

    end
  end
end
