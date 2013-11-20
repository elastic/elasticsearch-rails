module Elasticsearch
  module Model

    # Provides methods for getting and setting index name and document type for the model
    #
    module Naming

      module ClassMethods

        # Get or set the name of the index
        #
        # @example Set the index name for the `Article` model
        #
        #     class Article
        #       index_name "articles-#{Rails.env}"
        #     end
        #
        # @example Directly set the index name for the `Article` model
        #
        #     Article.index_name "articles-#{Rails.env}"
        #
        # TODO: Dynamic names a la Tire -- `Article.index_name { "articles-#{Time.now.year}" }`
        #
        def index_name name=nil
          @index_name = name || @index_name || self.model_name.collection
        end

        # Get or set the document type
        #
        # @example Set the document type for the `Article` model
        #
        #     class Article
        #       document_type "my-article"
        #     end
        #
        # @example Directly set the document type for the `Article` model
        #
        #     Article.document_type "my-article"
        #
        def document_type name=nil
          @document_type = name || @document_type || self.model_name.element
        end

      end

      module InstanceMethods

        # Get or set the index name for the model instance
        #
        # @example Set the index name for an instance of the `Article` model
        #
        #     @article.index_name "articles-#{@article.user_id}"
        #     @article.__elasticsearch__.update_document
        #
        def index_name name=nil
          @index_name = name || @index_name || self.class.index_name
        end

        # @example Set the document type for an instance of the `Article` model
        #
        #     @article.document_type "my-article"
        #     @article.__elasticsearch__.update_document
        #
        def document_type name=nil
          @document_type = name || @document_type || self.class.document_type
        end
      end

    end
  end
end
