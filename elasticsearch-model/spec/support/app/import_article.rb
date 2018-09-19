class ImportArticle < ActiveRecord::Base
  include Elasticsearch::Model

  scope :popular, -> { where('views >= 5') }

  mapping do
    indexes :title,      type: 'text'
    indexes :views,      type: 'integer'
    indexes :numeric,    type: 'integer'
    indexes :created_at, type: 'date'
  end
end
