module Elasticsearch
  module Model
    module Naming

      module ClassMethods

        # Get or set the name of the index
        #
        # TODO: Dynamic names a la Tire -- `Article.index_name { "articles-#{Time.now.year}" }`
        #
        def index_name name=nil
          @index_name = name || @index_name || self.model_name.collection
        end

        # Get or set the document type
        #
        def document_type name=nil
          @document_type = name || @document_type || self.model_name.element
        end

      end

      module InstanceMethods
        def index_name name=nil
          @index_name = name || @index_name || self.class.index_name
        end

        def document_type name=nil
          @document_type = name || @document_type || self.class.document_type
        end
      end

    end
  end
end
