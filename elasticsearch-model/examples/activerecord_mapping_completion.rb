# Licensed to Elasticsearch B.V. under one or more contributor
# license agreements. See the NOTICE file distributed with
# this work for additional information regarding copyright
# ownership. Elasticsearch B.V. licenses this file to you under
# the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

require 'ansi'
require 'active_record'
require 'elasticsearch/model'

ActiveRecord::Base.logger = ActiveSupport::Logger.new(STDOUT)
ActiveRecord::Base.establish_connection( adapter: 'sqlite3', database: ":memory:" )

ActiveRecord::Schema.define(version: 1) do
  create_table :articles do |t|
    t.string :title
    t.date   :published_at
    t.timestamps
  end
end

class Article < ActiveRecord::Base
  include Elasticsearch::Model
  include Elasticsearch::Model::Callbacks

  mapping do
    indexes :title, type: 'text' do
      indexes :suggest, type: 'completion'
    end
    indexes :url, type: 'keyword'
  end

  def as_indexed_json(options={})
    as_json.merge 'url' => "/articles/#{id}"
  end
end

Article.__elasticsearch__.client = Elasticsearch::Client.new log: true

# Create index

Article.__elasticsearch__.create_index! force: true

# Store data

Article.delete_all
Article.create title: 'Foo'
Article.create title: 'Bar'
Article.create title: 'Foo Foo'
Article.__elasticsearch__.refresh_index!

# Search and suggest

response_1 = Article.search 'foo';

puts "Article search:".ansi(:bold),
     response_1.to_a.map { |d| "Title: #{d.title}" }.inspect.ansi(:bold, :yellow)

response_2 = Article.search \
  query: {
    match: { title: 'foo' }
  },
  suggest: {
    articles: {
      text: 'foo',
      completion: { field: 'title.suggest' }
    }
  },
  _source: ['title', 'url']

puts "Article search with suggest:".ansi(:bold),
     response_2.response['suggest']['articles'].first['options'].map { |d| "#{d['text']} -> #{d['_source']['url']}" }.
     inspect.ansi(:bold, :blue)

require 'pry'; binding.pry;
