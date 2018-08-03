module Elasticsearch
  module Persistence
    module Repository

      # Save and delete documents in Elasticsearch
      #
      module Store

        # Base methods for the class and single repository instance.
        #
        # @return [ Array<Symbol> ] The base methods.
        #
        # @since 6.0.0
        BASE_METHODS = [ :save,
                         :update,
                         :delete ].freeze

        def self.included(base)

          # Define each base method explicitly so that #method_missing does not have to be used
          #  each time the method is called.
          #
          BASE_METHODS.each do |_method|
            base.class_eval("def self.#{_method}(*args); instance.send(__method__, *args); end", __FILE__, __LINE__)
          end
        end

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
        # @return {Hash} The response from Elasticsearch
        #
        def update(document_or_id, options={})
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
          client.update( { index: index_name, id: id, type: type, body: body } )
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
