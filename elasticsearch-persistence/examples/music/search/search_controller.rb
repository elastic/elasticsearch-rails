class SearchController < ApplicationController

  def index
    tags = { pre_tags: '<em class="hl">', post_tags: '</em>' }
    @artists = Artist.search \
      query: {
        multi_match: {
          query: params[:q],
          fields: ['name^10','members^2','profile']
        }
      },
      highlight: {
        tags_schema: 'styled',
        fields: {
          name:    { number_of_fragments: 0 },
          members_combined: { number_of_fragments: 0 },
          profile: { fragment_size: 50 }
        }
      }

    @albums = Album.search \
      query: {
        multi_match: {
          query: params[:q],
          fields: ['title^100','tracklist.title^10','notes^1']
        }
      },
      highlight: {
        tags_schema: 'styled',
        fields: {
          title: { number_of_fragments: 0 },
          'tracklist.title' => { number_of_fragments: 0 },
          notes: { fragment_size: 50 }
        }
      }
  end

  def suggest
    render json: Suggester.new(params)
  end
end
