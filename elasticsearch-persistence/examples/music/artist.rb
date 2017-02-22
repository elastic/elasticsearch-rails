class Artist
  include Elasticsearch::Persistence::Model

  index_name [Rails.application.engine_name, Rails.env].join('-')

  analyzed_and_raw = { fields: {
    name: { type: 'text', analyzer: 'snowball' },
    raw:  { type: 'keyword' }
  } }

  attribute :name, String, mapping: analyzed_and_raw

  attribute :profile
  attribute :date, Date

  attribute :members, String, default: [], mapping: analyzed_and_raw
  attribute :members_combined, String, default: [], mapping: { analyzer: 'snowball' }

  attribute :urls, String, default: []
  attribute :album_count, Integer, default: 0

  attribute :suggest, Hashie::Mash, mapping: {
    type: 'object',
    properties: {
      name: {
        type: 'object',
        properties: {
          input:   { type: 'completion' },
          output:  { type: 'keyword', index: false },
          payload: { type: 'object', enabled: false }
        }
      },
      member: {
        type: 'object',
        properties: {
          input:   { type: 'completion' },
          output:  { type: 'keyword', index: false },
          payload: { type: 'object', enabled: false }
        }
      }
    }
  }

  validates :name, presence: true

  def albums
    Album.search(
      { query: {
          has_parent: {
            type: 'artist',
            query: {
              bool: {
                filter: {
                  ids: { values: [ self.id ] }
                }
              }
            }
          }
        },
        sort: 'released',
        size: 100
      },
      { type: 'album' }
  )
  end

  def to_param
    [id, name.parameterize].join('-')
  end
end
