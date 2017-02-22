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
  end

  attribute :artist
  attribute :artist_id, String, mapping: { index: 'not_analyzed' }
  attribute :label, Hash, mapping: { type: 'object' }

  attribute :title
  attribute :released, Date
  attribute :notes
  attribute :uri

  attribute :tracklist, Array, mapping: { type: 'object' }

  attribute :styles
  attribute :meta, Meta, mapping: { type: 'object' }

  attribute :suggest, Hashie::Mash, mapping: {
    type: 'object',
    properties: {
      title: {
        type: 'object',
        properties: {
          input:   { type: 'completion' },
          output:  { type: 'keyword', index: false },
          payload: { type: 'object', enabled: false }
        }
      },
      track: {
        type: 'object',
        properties: {
          input:   { type: 'completion' },
          output:  { type: 'keyword', index: false },
          payload: { type: 'object', enabled: false }
        }
      }
    }
  }
end
