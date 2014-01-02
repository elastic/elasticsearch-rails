module Searchable
  extend ActiveSupport::Concern

  included do
    include Elasticsearch::Model

    # Customize the index name
    #
    index_name [File.basename(Rails.root).downcase, Rails.env.to_s].join('-')

    # Set up index configuration and mapping
    #
    settings index: { number_of_shards: 1, number_of_replicas: 0 } do
      mapping do
        indexes :title,      analyzer: 'snowball'
        indexes :created_at, type: 'date'

        indexes :authors do
          indexes :first_name
          indexes :last_name
          indexes :full_name, type: 'multi_field' do
            indexes :full_name
            indexes :raw, analyzer: 'keyword'
          end
        end

        indexes :categories, analyzer: 'keyword'

        indexes :comments, type: 'nested' do
          indexes :text
          indexes :author
        end
      end
    end

    # Customize the JSON serialization for Elasticsearch
    #
    def as_indexed_json(options={})
      self.as_json(
        include: { categories: { only: :title},
                   authors:    { methods: [:full_name], only: [:full_name] },
                   comments:   { only: :text }
                 })
    end
  end

  module ClassMethods

    # Search in title and content fields for `query`, include highlights in response
    #
    # @param query [String] The user query
    # @return [Elasticsearch::Model::Response::Response]
    #
    def search(query)
      __elasticsearch__.search(
        {
          query: {
            multi_match: {
              query: query,
              fields: ['title^10', 'content']
            }
          },
          highlight: {
            pre_tags: ['<em class="label label-highlight">'],
            post_tags: ['</em>'],
            fields: {
              title:   { number_of_fragments: 0 },
              content: { fragment_size: 25 }
            }
          }
        }
      )
    end
  end
end
