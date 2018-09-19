class Image
  include Mongoid::Document
  include Elasticsearch::Model
  include Elasticsearch::Model::Callbacks

  field :name, type: String
  attr_accessible :name if respond_to? :attr_accessible

  settings index: {number_of_shards: 1, number_of_replicas: 0} do
    mapping do
      indexes :name, type: 'text', analyzer: 'snowball'
      indexes :created_at, type: 'date'
    end
  end

  def as_indexed_json(options={})
    as_json(except: [:_id])
  end
end
