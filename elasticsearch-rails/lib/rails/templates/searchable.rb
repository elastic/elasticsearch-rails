module Searchable
  extend ActiveSupport::Concern

  included do
    include Elasticsearch::Model

    # Customize the index name
    #
    index_name [Rails.application.engine_name, Rails.env].join('_')

    # Set up index configuration and mapping
    #
    settings index: { number_of_shards: 1, number_of_replicas: 0 } do
      mapping do
        indexes :title, type: 'multi_field' do
          indexes :title,     analyzer: 'snowball'
          indexes :tokenized, analyzer: 'simple'
        end

        indexes :content, type: 'multi_field' do
          indexes :content,   analyzer: 'snowball'
          indexes :tokenized, analyzer: 'simple'
        end

        indexes :published_on, type: 'date'

        indexes :authors do
          indexes :full_name, type: 'multi_field' do
            indexes :full_name
            indexes :raw, analyzer: 'keyword'
          end
        end

        indexes :categories, analyzer: 'keyword'

        indexes :comments, type: 'nested' do
          indexes :body, analyzer: 'snowball'
          indexes :stars
          indexes :pick
          indexes :user, analyzer: 'keyword'
          indexes :user_location, type: 'multi_field' do
            indexes :user_location
            indexes :raw, analyzer: 'keyword'
          end
        end
      end
    end

    # Set up callbacks for updating the index on model changes
    #
    after_commit lambda { Indexer.perform_async(:index,  self.class.to_s, self.id) }, on: :create
    after_commit lambda { Indexer.perform_async(:update, self.class.to_s, self.id) }, on: :update
    after_commit lambda { Indexer.perform_async(:delete, self.class.to_s, self.id) }, on: :destroy
    after_touch  lambda { Indexer.perform_async(:update, self.class.to_s, self.id) }

    # Customize the JSON serialization for Elasticsearch
    #
    def as_indexed_json(options={})
      hash = self.as_json(
        include: { authors:    { methods: [:full_name], only: [:full_name] },
                   comments:   { only: [:body, :stars, :pick, :user, :user_location] }
                 })
      hash['categories'] = self.categories.map(&:title)
      hash
    end

    # Search in title and content fields for `query`, include highlights in response
    #
    # @param query [String] The user query
    # @return [Elasticsearch::Model::Response::Response]
    #
    def self.search(query, options={})

      # Prefill and set the filters (top-level `post_filter` and aggregation `filter` elements)
      #
      __set_filters = lambda do |key, f|
        @search_definition[:post_filter][:and] ||= []
        @search_definition[:post_filter][:and]  |= [f]

        @search_definition[:aggregations][key.to_sym][:filter][:bool][:must] ||= []
        @search_definition[:aggregations][key.to_sym][:filter][:bool][:must]  |= [f]
      end

      @search_definition = {
        query: {},

        highlight: {
          pre_tags: ['<em class="label label-highlight">'],
          post_tags: ['</em>'],
          fields: {
            title:    { number_of_fragments: 0 },
            abstract: { number_of_fragments: 0 },
            content:  { fragment_size: 50 }
          }
        },

        post_filter: {},

        aggregations: {
          categories: {
            filter: { bool: { must: [ match_all: {} ] } },
            aggregations: { categories: { terms: { field: 'categories' } } }
          },
          authors: {
            filter: { bool: { must: [ match_all: {} ] } },
            aggregations: { authors: { terms: { field: 'authors.full_name.raw' } } }
          },
          published: {
            filter: { bool: { must: [ match_all: {} ] } },
            aggregations: {
              published: { date_histogram: { field: 'published_on', interval: 'week' } }
            }
          }
        }
      }

      unless query.blank?
        @search_definition[:query] = {
          bool: {
            should: [
              { multi_match: {
                  query: query,
                  fields: ['title^10', 'abstract^2', 'content'],
                  operator: 'and'
                }
              }
            ]
          }
        }
      else
        @search_definition[:query] = { match_all: {} }
        @search_definition[:sort]  = { published_on: 'desc' }
      end

      if options[:category]
        f = { term: { categories: options[:category] } }

        __set_filters.(:authors, f)
        __set_filters.(:published, f)
      end

      if options[:author]
        f = { term: { 'authors.full_name.raw' => options[:author] } }

        __set_filters.(:categories, f)
        __set_filters.(:published, f)
      end

      if options[:published_week]
        f = {
          range: {
            published_on: {
              gte: options[:published_week],
              lte: "#{options[:published_week]}||+1w"
            }
          }
        }

        __set_filters.(:categories, f)
        __set_filters.(:authors, f)
      end

      if query.present? && options[:comments]
        @search_definition[:query][:bool][:should] ||= []
        @search_definition[:query][:bool][:should] << {
          nested: {
            path: 'comments',
            query: {
              multi_match: {
                query: query,
                fields: ['comments.body'],
                operator: 'and'
              }
            }
          }
        }
        @search_definition[:highlight][:fields].update 'comments.body' => { fragment_size: 50 }
      end

      if options[:sort]
        @search_definition[:sort]  = { options[:sort] => 'desc' }
        @search_definition[:track_scores] = true
      end

      unless query.blank?
        @search_definition[:suggest] = {
          text: query,
          suggest_title: {
            term: {
              field: 'title.tokenized',
              suggest_mode: 'always'
            }
          },
          suggest_body: {
            term: {
              field: 'content.tokenized',
              suggest_mode: 'always'
            }
          }
        }
      end

      __elasticsearch__.search(@search_definition)
    end
  end
end
