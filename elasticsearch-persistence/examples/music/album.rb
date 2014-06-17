class Meta
  include Virtus.model

  attribute :rating
  attribute :have
  attribute :want
  attribute :formats
end

class Album
  include Elasticsearch::Persistence::Model

  index_name [Rails.application.engine_name, Rails.env].join('-')

  mapping _parent: { type: 'artist' } do
    indexes :suggest_title, type: 'completion', payloads: true
    indexes :suggest_track, type: 'completion', payloads: true
  end

  attribute :artist
  attribute :artist_id, String, mapping: { index: 'not_analyzed' }
  attribute :label, Hash, mapping: { type: 'object' }

  attribute :title
  attribute :suggest_title, String, default: {}, mapping: { type: 'completion', payloads: true }
  attribute :released, Date
  attribute :notes
  attribute :uri

  attribute :tracklist, Array, mapping: { type: 'object' }

  attribute :styles
  attribute :meta, Meta, mapping: { type: 'object' }
end
