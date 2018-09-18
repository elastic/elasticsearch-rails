class ::Article < ActiveRecord::Base
  include Elasticsearch::Model
  include Elasticsearch::Model::Callbacks

  document_type 'article'

  settings index: {number_of_shards: 1, number_of_replicas: 0} do
    mapping do
      indexes :title, type: 'text', analyzer: 'snowball'
      indexes :body, type: 'text'
      indexes :clicks, type: 'integer'
      indexes :created_at, type: 'date'
    end
  end

  def as_indexed_json(options = {})
    attributes
        .symbolize_keys
        .slice(:title, :body, :clicks, :created_at)
        .merge(suggest_title: title)
  end
end
