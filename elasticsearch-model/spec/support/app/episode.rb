class Episode < ActiveRecord::Base
  include Elasticsearch::Model
  include Elasticsearch::Model::Callbacks

  settings index: {number_of_shards: 1, number_of_replicas: 0} do
    mapping do
      indexes :name, type: 'text', analyzer: 'snowball'
      indexes :created_at, type: 'date'
    end
  end
end
