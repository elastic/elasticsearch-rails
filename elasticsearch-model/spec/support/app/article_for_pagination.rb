class ::ArticleForPagination < ActiveRecord::Base
  include Elasticsearch::Model

  scope :published, -> { where(published: true) }

  settings index: { number_of_shards: 1, number_of_replicas: 0 } do
    mapping do
      indexes :title,      type: 'text', analyzer: 'snowball'
      indexes :created_at, type: 'date'
    end
  end
end
