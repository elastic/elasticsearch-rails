class ::ArticleWithCustomSerialization < ActiveRecord::Base
  include Elasticsearch::Model
  include Elasticsearch::Model::Callbacks

  mapping do
    indexes :title
  end

  def as_indexed_json(options={})
    # as_json(options.merge root: false).slice('title')
    { title: self.title }
  end
end
