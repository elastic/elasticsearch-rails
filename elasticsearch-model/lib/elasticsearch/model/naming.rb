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
        # @example Set the index name for the `Article` model and re-evaluate it on each call
        #
        #     class Article
        #       index_name { "articles-#{Time.now.year}" }
        #     end
        #
        # @example Directly set the index name for the `Article` model
        #
        #     Article.index_name "articles-#{Rails.env}"
        #
        #
        def index_name name=nil, &block
          if name || block_given?
            return (@index_name = name || block)
          end

          if @index_name.respond_to?(:call)
            @index_name.call
          else
            @index_name || implicit(:index_name)
          end
        end

        # Set the index name
        #
        # @see index_name
        def index_name=(name)
          @index_name = name
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
          @document_type = name || @document_type || implicit(:document_type)
        end


        # Set the document type
        #
        # @see document_type
        #
        def document_type=(name)
          @document_type = name
        end

        private

          def implicit(prop)
            value = nil

            if Elasticsearch::Model.inheritance_enabled
              self.ancestors.each do |klass|
                next if klass == self
                break if value = klass.respond_to?(prop) && klass.send(prop)
              end
            end

            value || self.send("default_#{prop}")
          end

          def default_index_name
            self.model_name.collection.gsub(/\//, '-')
          end

          def default_document_type
            self.model_name.element
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
        def index_name name=nil, &block
          if name || block_given?
            return (@index_name = name || block)
          end

          if @index_name.respond_to?(:call)
            @index_name.call
          else
            @index_name || self.class.index_name
          end
        end

        # Set the index name
        #
        # @see index_name
        def index_name=(name)
          @index_name = name
        end

        # @example Set the document type for an instance of the `Article` model
        #
        #     @article.document_type "my-article"
        #     @article.__elasticsearch__.update_document
        #
        def document_type name=nil
          @document_type = name || @document_type || self.class.document_type
        end

        # Set the document type
        #
        # @see document_type
        #
        def document_type=(name)
          @document_type = name
        end
      end

    end
  end
end
