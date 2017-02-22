class Suggester
  attr_reader :response

  def initialize(params={})
    @term = params[:term]
  end

  def response
    @response ||= begin
      Elasticsearch::Persistence.client.search \
      index: Artist.index_name,
      body: {
        suggest: {
          artists: {
            text: @term,
            completion: { field: 'suggest.name.input', size: 25 }
          },
          members: {
            text: @term,
            completion: { field: 'suggest.member.input', size: 25 }
          },
          albums: {
            text: @term,
            completion: { field: 'suggest.title.input', size: 25 }
          },
          tracks: {
            text: @term,
            completion: { field: 'suggest.track.input', size: 25 }
          }
        },
        _source: ['suggest.*']
      }
    end
  end

  def as_json(options={})
    return [] unless response['suggest']

    output = [
      { label: 'Bands',
        value: response['suggest']['artists'][0]['options'].map do |d|
          { text: d['_source']['suggest']['name']['output'],
            url:  d['_source']['suggest']['name']['payload']['url'] }
        end
      },

      { label: 'Albums',
        value: response['suggest']['albums'][0]['options'].map do |d|
          { text: d['_source']['suggest']['title']['output'],
            url:  d['_source']['suggest']['title']['payload']['url'] }
        end
      },

      { label: 'Band Members',
        value: response['suggest']['members'][0]['options'].map do |d|
          { text: "#{d['text']} (#{d['_source']['suggest']['member']['output']})",
            url:  d['_source']['suggest']['member']['payload']['url'] }
        end
      },

      { label: 'Album Tracks',
        value: response['suggest']['tracks'][0]['options'].map do |d|
          { text: "#{d['text']} (#{d['_source']['suggest']['track']['output']})",
            url:  d['_source']['suggest']['track']['payload']['url'] }
        end
      }
    ]
  end
end
