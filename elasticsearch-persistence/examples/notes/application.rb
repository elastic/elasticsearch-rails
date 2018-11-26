# Licensed to Elasticsearch B.V. under one or more contributor
# license agreements. See the NOTICE file distributed with
# this work for additional information regarding copyright
# ownership. Elasticsearch B.V. licenses this file to you under
# the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#	http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

$LOAD_PATH.unshift File.expand_path('../../../lib/', __FILE__)

require 'sinatra/base'

require 'multi_json'
require 'oj'
require 'hashie/mash'

require 'elasticsearch'
require 'elasticsearch/model'
require 'elasticsearch/persistence'

class Note
  attr_reader :attributes

  def initialize(attributes={})
    @attributes = Hashie::Mash.new(attributes)
    __add_date
    __extract_tags
    __truncate_text
    self
  end

  def method_missing(method_name, *arguments, &block)
    attributes.respond_to?(method_name) ? attributes.__send__(method_name, *arguments, &block) : super
  end

  def respond_to?(method_name, include_private=false)
    attributes.respond_to?(method_name) || super
  end

  def tags; attributes.tags || []; end

  def to_hash
    @attributes.to_hash
  end

  def __extract_tags
    tags = attributes['text'].scan(/(\[\w+\])/).flatten if attributes['text']
    unless tags.nil? || tags.empty?
      attributes.update 'tags' => tags.map { |t| t.tr('[]', '') }
      attributes['text'].gsub!(/(\[\w+\])/, '').strip!
    end
  end

  def __add_date
    attributes['created_at'] ||=  Time.now.utc.iso8601
  end

  def __truncate_text
    attributes['text'] = attributes['text'][0...80] + ' (...)' if attributes['text'] && attributes['text'].size > 80
  end
end

class NoteRepository
  include Elasticsearch::Persistence::Repository
  include Elasticsearch::Persistence::Repository::DSL

  client Elasticsearch::Client.new url: ENV['ELASTICSEARCH_URL'], log: true

  index_name :notes
  document_type  :note

  mapping do
    indexes :text,       analyzer: 'snowball'
    indexes :tags,       type:     'keyword'
    indexes :created_at, type:     'date'
  end

  def deserialize(document)
    Note.new document['_source'].merge('id' => document['_id'])
  end
end unless defined?(NoteRepository)

class Application < Sinatra::Base
  enable :logging
  enable :inline_templates
  enable :method_override

  configure :development do
    enable   :dump_errors
    disable  :show_exceptions

    require  'sinatra/reloader'
    register Sinatra::Reloader
  end

  set :repository, NoteRepository.new
  set :per_page,   25

  get '/' do
    @page  = [ params[:p].to_i, 1 ].max

    @notes = settings.repository.search \
               query: ->(q, t) do
                query = if q && !q.empty?
                  { match: { text: q } }
                else
                  { match_all: {} }
                end

                filter = if t && !t.empty?
                  { term: { tags: t } }
                end

                if filter
                  { bool: { must: [ query ], filter: filter } }
                else
                  query
                end
               end.(params[:q], params[:t]),

               sort: [{created_at: {order: 'desc'}}],

               size: settings.per_page,
               from: settings.per_page * (@page-1),

               aggregations: { tags: { terms: { field: 'tags' } } },

               highlight: { fields: { text: { fragment_size: 0, pre_tags: ['<em class="hl">'],post_tags: ['</em>'] } } }

    erb :index
  end

  post '/' do
    unless params[:text].empty?
      @note = Note.new params
      settings.repository.save(@note, refresh: true)
    end

    redirect back
  end

  delete '/:id' do |id|
    settings.repository.delete(id, refresh: true)
    redirect back
  end
end

Application.run! if $0 == __FILE__

__END__

@@ layout
<!DOCTYPE html>
<html>
<head>
  <title>Notes</title>
  <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
  <style>
    body   { color: #222; background: #fff; font: normal 80%/120% 'Helvetica Neue', sans-serif; margin: 4em; position: relative; }
    header { color: #666; border-bottom: 2px solid #666;  }
    header:after { display: table; content: ""; line-height: 0; clear: both; }
    #left  { width: 20em; float: left }
    #main  { margin-left: 20em; }
    header h1 { font-weight: normal; float: left; padding: 0.4em 0 0 0; margin: 0; }
    header form { margin-left: 19.5em; }
    header form input { font-size: 120%; width: 40em; border: none; padding: 0.5em; position: relative; bottom: -0.2em; background: transparent; }
    header form input:focus { outline-width: 0; }

    #left h2 { color: #999; font-size: 160%; font-weight: normal; text-transform: uppercase; letter-spacing: -0.05em; }
    #left h2 { border-top: 2px solid #999; width: 9.4em; padding: 0.5em 0 0.5em 0; margin: 0; }
    #left textarea { font: normal 140%/140% monospace; border: 1px solid #999; padding: 0.5em; width: 12em; }
    #left form p { margin: 0; }
    #left a { color: #000; }
    #left small.c { color: #333; background: #ccc; text-align: center; min-width: 1.75em; min-height: 1.5em; border-radius: 1em; display: inline-block; padding-top: 0.25em; float: right; margin-right: 6em; }
    #left small.i { color: #ccc; background: #333; }

    #facets { list-style-type: none; padding: 0; margin: 0 0 1em 0; }
    #facets li { padding: 0 0 0.5em 0; }

    .note   { border-bottom: 1px solid #999; position: relative; padding: 0.5em 0; }
    .note p { font-size: 140%; }
    .note small { font-size: 70%; color: #999; }
    .note small.d { border-left: 1px solid #999; padding-left: 0.5em; margin-left: 0.5em; }
    .note em.hl { background: #fcfcad; border-radius: 0.5em; padding: 0.2em 0.4em 0.2em 0.4em; }
    .note strong.t { color: #fff; background: #999; font-size: 70%; font-weight: bold; border-radius: 0.6em; padding: 0.2em 0.6em 0.3em 0.7em; }
    .note form { position: absolute; bottom: 1.5em; right: 1em; }

    .pagination { color: #000; font-weight: bold; text-align: right;  }
    .pagination:visited { color: #000; }
    .pagination a        { text-decoration: none; }
    .pagination:hover a  { text-decoration: underline; }
}

  </style>
</head>
<body>
<%= yield %>
</body>
</html>

@@ index

<header>
  <h1>Notes</h1>
  <form action="/" method='get'>
    <input type="text" name="q" value="<%= params[:q] %>" id="q" autofocus="autofocus" placeholder="type a search query and press enter..." />
  </form>
</header>

<section id="left">
  <p><a href="/">All notes</a> <small class="c i"><%= @notes.size %></small></p>
  <ul id="facets">
  <% @notes.response.aggregations.tags.buckets.each do |term| %>
  <li><a href="/?t=<%= term['key'] %>"><%= term['key'] %></a> <small class="c"><%= term['doc_count'] %></small></li>
  <% end %>
  </ul>
  <h2>Add a note</h2>
  <form action="/" method='post'>
    <p><textarea name="text" rows="5"></textarea></p>
    <p><input type="submit" accesskey="s" value="Save" /></p>
  </form>
</section>

<section id="main">
<% if @notes.empty?  %>
  <p>No notes found.</p>
<% end %>

<% @notes.each_with_hit do |note, hit|  %>
  <div class="note">
    <p>
      <%= hit.highlight && hit.highlight.size > 0 ? hit.highlight.text.first : note.text %>

      <% note.tags.each do |tag| %> <strong class="t"><%= tag %></strong><% end %>
      <small class="d"><%= Time.parse(note.created_at).strftime('%d/%m/%Y %H:%M') %></small>

      <form action="/<%= note.id %>" method="post"><input type="hidden" name="_method" value="delete" /><button>Delete</button></form>
    </p>
  </div>
<% end  %>

<% if @notes.size > 0 && @page.next <= @notes.total / settings.per_page %>
  <p class="pagination"><a href="?p=<%= @page.next %>">&rarr; Load next</a></p>
<% end %>
</section>
