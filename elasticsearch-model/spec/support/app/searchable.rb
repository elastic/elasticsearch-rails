module Searchable
  extend ActiveSupport::Concern

  included do
    include Elasticsearch::Model
    include Elasticsearch::Model::Callbacks

    # Set up the mapping
    #
    settings index: { number_of_shards: 1, number_of_replicas: 0 } do
      mapping do
        indexes :title,      analyzer: 'snowball'
        indexes :created_at, type: 'date'

        indexes :authors do
          indexes :first_name
          indexes :last_name
            indexes :full_name, type: 'text' do
            indexes :raw, type: 'keyword'
          end
        end

        indexes :categories, type: 'keyword'

        indexes :comments, type: 'nested' do
          indexes :text
          indexes :author
        end
      end
    end

    # Customize the JSON serialization for Elasticsearch
    #
    def as_indexed_json(options={})
      {
          title: title,
          text:  text,
          categories: categories.map(&:title),
          authors:    authors.as_json(methods: [:full_name], only: [:full_name, :first_name, :last_name]),
          comments:   comments.as_json(only: [:text, :author])
      }
    end

    # Update document in the index after touch
    #
    after_touch() { __elasticsearch__.index_document }
  end
end
