class ::ArticleWithDynamicIndexName < ActiveRecord::Base
  include Elasticsearch::Model
  include Elasticsearch::Model::Callbacks

  def self.counter=(value)
    @counter = 0
  end

  def self.counter
    (@counter ||= 0) && @counter += 1
  end

  mapping    { indexes :title }
  index_name { "articles-#{counter}" }
end
