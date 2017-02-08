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
    indexes :title
    indexes :title_suggest, type: 'completion', payloads: true
  end

  def as_indexed_json(options={})
    as_json.merge \
    title_suggest: {
      input:  title,
      output: title,
      payload: { url: "/articles/#{id}" }
    }
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

Rails.logger.info "Article search:".ansi(:bold)
Rails.logger.info response_1.to_a.map { |d| "Title: #{d.title}" }.inspect.ansi(:bold, :yellow)

response_2 = Article.__elasticsearch__.client.suggest \
  index: Article.index_name,
  body: {
    articles: {
      text: 'foo',
      completion: { field: 'title_suggest', size: 25 }
    }
  };

Rails.logger.info "Article suggest:".ansi(:bold)
Rails.logger.info response_2['articles'].first['options'].map { |d| "#{d['text']} -> #{d['payload']['url']}" }.
                    inspect.ansi(:bold, :green)

require 'pry'; binding.pry;
