class ::MongoidArticle
  include Mongoid::Document
  include Elasticsearch::Model
  include Elasticsearch::Model::Callbacks

  field :id, type: String
  field :title, type: String
  field :views, type: Integer
  attr_accessible :title if respond_to? :attr_accessible

  settings index: { number_of_shards: 1, number_of_replicas: 0 } do
    mapping do
      indexes :title,      type: 'text', analyzer: 'snowball'
      indexes :created_at, type: 'date'
    end
  end

  def as_indexed_json(options={})
    as_json(except: [:id, :_id])
  end
end
