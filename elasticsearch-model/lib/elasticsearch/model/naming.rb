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
  module Model

    # Provides methods for getting and setting index name and document type for the model
    #
    module Naming

      DEFAULT_DOC_TYPE = '_doc'.freeze

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

        private

          def implicit(prop)
            self.send("default_#{prop}")
          end

          def default_index_name
            self.model_name.collection.gsub(/\//, '-')
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
      end
    end
  end
end
