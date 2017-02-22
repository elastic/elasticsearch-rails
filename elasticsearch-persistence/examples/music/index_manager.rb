require 'open-uri'

class IndexManager
  def self.create_index(options={})
    client     = Artist.gateway.client
    index_name = Artist.index_name

    client.indices.delete index: index_name rescue nil if options[:force]

    settings = Artist.settings.to_hash.merge(Album.settings.to_hash)
    mappings = Artist.mappings.to_hash.merge(Album.mappings.to_hash)

    client.indices.create index: index_name,
                          body: {
                            settings: settings.to_hash,
                            mappings: mappings.to_hash }
  end

  def self.import_from_yaml(source, options={})
    create_index force: true if options[:force]

    input   = open(source)
    artists = YAML.load_documents input

    artists.each do |artist|
      Artist.create artist.update(
        'album_count' => artist['releases'].size,
        'members_combined' => artist['members'].join(', '),
        'suggest' => {
          'name' => {
            'input' => { 'input' => artist['namevariations'].unshift(artist['name']).reject { |d| d.to_s.empty? } },
            'output' => artist['name'],
            'payload' => {
              'url' => "/artists/#{artist['id']}"
            }
          },
          'member' => {
            'input' => { 'input' => artist['members'] },
            'output' => artist['name'],
            'payload' => {
              'url' => "/artists/#{artist['id']}"
            }
          }
        }
      )

      artist['releases'].each do |album|
        album.update(
          'suggest' => {
            'title' => {
              'input' => { 'input' => album['title'] },
              'output' => album['title'],
              'payload' => {
                'url' => "/artists/#{artist['id']}#album_#{album['id']}"
              }
            },
            'track' => {
              'input' => { 'input' => album['tracklist'].map { |d| d['title'] }.reject { |d| d.to_s.empty? } },
              'output' => album['title'],
              'payload' => {
                'url' => "/artists/#{artist['id']}#album_#{album['id']}"
              }
            }
          }
        )
        album['notes'] = album['notes'].to_s.gsub(/<.+?>/, '').gsub(/ {2,}/, '')
        album['released'] = nil if album['released'] < 1

        Album.create album, id: album['id'], parent: artist['id']
      end
    end
  end
end
