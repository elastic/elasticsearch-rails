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
        indexes :title, type: 'text' do
          indexes :title,     analyzer: 'snowball'
          indexes :tokenized, analyzer: 'simple'
        end

        indexes :content, type: 'text'  do
          indexes :content,   analyzer: 'snowball'
          indexes :tokenized, analyzer: 'simple'
        end

        indexes :published_on, type: 'date'

        indexes :authors do
          indexes :full_name, type: 'text' do
            indexes :full_name
            indexes :raw, type: 'keyword'
          end
        end

        indexes :categories, type: 'keyword'

        indexes :comments, type: 'nested' do
          indexes :body, analyzer: 'snowball'
          indexes :stars
          indexes :pick
          indexes :user, type: 'keyword'
          indexes :user_location, type: 'text' do
            indexes :user_location
            indexes :raw, type: 'keyword'
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

    # Return documents matching the user's query, include highlights and aggregations in response,
    # and implement a "cross" faceted navigation
    #
    # @param q [String] The user query
    # @return [Elasticsearch::Model::Response::Response]
    #
    def self.search(q, options={})
      @search_definition = Elasticsearch::DSL::Search.search do
        query do

          # If a user query is present...
          #
          unless q.blank?
            bool do

              # ... search in `title`, `abstract` and `content`, boosting `title`
              #
              should do
                multi_match do
                  query    q
                  fields   ['title^10', 'abstract^2', 'content']
                  operator 'and'
                end
              end

              # ... search in comment body if user checked the comments checkbox
              #
              if q.present? && options[:comments]
                should do
                  nested do
                    path :comments
                    query do
                      multi_match do
                        query q
                        fields   'comments.body'
                        operator 'and'
                      end
                    end
                  end
                end
              end
            end

          # ... otherwise, just return all articles
          else
            match_all
          end
        end

        # Filter the search results based on user selection
        #
        post_filter do
          bool do
            must { term categories: options[:category] } if options[:category]
            must { match_all } if options.keys.none? { |k| [:c, :a, :w].include? k }
            must { term 'authors.full_name.raw' => options[:author] } if options[:author]
            must { range published_on: { gte: options[:published_week], lte: "#{options[:published_week]}||+1w" } } if options[:published_week]
          end
        end

        # Return top categories for faceted navigation
        #
        aggregation :categories do
          # Filter the aggregation with any selected `author` and `published_week`
          #
          f = Elasticsearch::DSL::Search::Filters::Bool.new
          f.must { match_all }
          f.must { term 'authors.full_name.raw' => options[:author] } if options[:author]
          f.must { range published_on: { gte: options[:published_week], lte: "#{options[:published_week]}||+1w" } } if options[:published_week]

          filter f.to_hash do
            aggregation :categories do
              terms field: 'categories'
            end
          end
        end

        # Return top authors for faceted navigation
        #
        aggregation :authors do
          # Filter the aggregation with any selected `category` and `published_week`
          #
          f = Elasticsearch::DSL::Search::Filters::Bool.new
          f.must { match_all }
          f.must { term categories: options[:category] } if options[:category]
          f.must { range published_on: { gte: options[:published_week], lte: "#{options[:published_week]}||+1w" } } if options[:published_week]

          filter f do
            aggregation :authors do
              terms field: 'authors.full_name.raw'
            end
          end
        end

        # Return the published date ranges for faceted navigation
        #
        aggregation :published do
          # Filter the aggregation with any selected `author` and `category`
          #
          f = Elasticsearch::DSL::Search::Filters::Bool.new
          f.must { match_all }
          f.must { term 'authors.full_name.raw' => options[:author] } if options[:author]
          f.must { term categories: options[:category] } if options[:category]

          filter f do
            aggregation :published do
              date_histogram do
                field    'published_on'
                interval 'week'
              end
            end
          end
        end

        # Highlight the snippets in results
        #
        highlight do
          fields title:    { number_of_fragments: 0 },
                 abstract: { number_of_fragments: 0 },
                 content:  { fragment_size: 50 }

          field  'comments.body', fragment_size: 50 if q.present? && options[:comments]

          pre_tags  '<em class="label label-highlight">'
          post_tags '</em>'
        end

        case
          # By default, sort by relevance, but when a specific sort option is present, use it ...
          #
          when options[:sort]
            sort options[:sort].to_sym => 'desc'
            track_scores true
          #
          # ... when there's no user query, sort on published date
          #
          when q.blank?
            sort published_on: 'desc'
        end

        # Return suggestions unless there's no query from the user
        unless q.blank?
          suggest :suggest_title, text: q, term: { field: 'title.tokenized', suggest_mode: 'always' }
          suggest :suggest_body,  text: q, term: { field: 'content.tokenized', suggest_mode: 'always' }
        end
      end

      __elasticsearch__.search(@search_definition)
    end
  end
end
