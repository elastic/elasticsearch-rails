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
