class Artist
  include Elasticsearch::Persistence::Model

  index_name [Rails.application.engine_name, Rails.env].join('-')

  analyzed_and_raw = { fields: {
    name: { type: 'string', analyzer: 'snowball' },
    raw:  { type: 'string', analyzer: 'keyword' }
  } }

  attribute :name, String, mapping: analyzed_and_raw
  attribute :suggest_name, String, default: {}, mapping: { type: 'completion', payloads: true }

  attribute :profile
  attribute :date, Date

  attribute :members, String, default: [], mapping: analyzed_and_raw
  attribute :members_combined, String, default: [], mapping: { analyzer: 'snowball' }
  attribute :suggest_member, String, default: {}, mapping: { type: 'completion', payloads: true }

  attribute :urls, String, default: []
  attribute :album_count, Integer, default: 0

  validates :name, presence: true

  def albums
    Album.search(
      { query: {
          has_parent: {
            type: 'artist',
            query: {
              filtered: {
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
