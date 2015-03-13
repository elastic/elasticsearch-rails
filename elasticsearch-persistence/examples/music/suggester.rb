class Suggester
  attr_reader :response

  def initialize(params={})
    @term = params[:term]
  end

  def response
    @response ||= begin
      Elasticsearch::Persistence.client.suggest \
      index: Artist.index_name,
      body: {
        artists: {
          text: @term,
          completion: { field: 'suggest_name', size: 25 }
        },
        members: {
          text: @term,
          completion: { field: 'suggest_member', size: 25 }
        },
        albums: {
          text: @term,
          completion: { field: 'suggest_title', size: 25 }
        },
        tracks: {
          text: @term,
          completion: { field: 'suggest_track', size: 25 }
        }
      }
    end
  end

  def as_json(options={})
    response
      .except('_shards')
      .reduce([]) do |sum,d|
        # category = { d.first => d.second.first['options'] }
        item = { :label => d.first.titleize, :value => d.second.first['options'] }
        sum << item
      end
      .reject do |d|
        d[:value].empty?
      end
  end
end
