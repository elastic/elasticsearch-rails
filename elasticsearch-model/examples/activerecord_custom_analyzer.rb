# Custom Analyzer for ActiveRecord integration with Elasticsearch
# ===============================================================

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'ansi'
require 'logger'

require 'active_record'
require 'elasticsearch/model'

ActiveRecord::Base.logger = ActiveSupport::Logger.new(STDOUT)
ActiveRecord::Base.establish_connection( adapter: 'sqlite3', database: ":memory:" )

ActiveRecord::Schema.define(version: 1) do
  create_table :articles do |t|
    t.string :title
    t.date    :published_at
    t.timestamps
  end
end

Elasticsearch::Model.client.transport.logger = ActiveSupport::Logger.new(STDOUT)
Elasticsearch::Model.client.transport.logger.formatter = lambda { |s, d, p, m| "#{m.ansi(:faint)}\n" }

class Article < ActiveRecord::Base
  include Elasticsearch::Model

  settings index: {
    number_of_shards: 1,
    number_of_replicas: 0,
    analysis: {
      analyzer: {
        pattern: {
          type: 'pattern',
          pattern: "_|-|\\.",
          lowercase: true
        },
        trigram: {
          tokenizer: 'trigram'
        }
      },
      tokenizer: {
        trigram: {
          type: 'ngram',
          min_gram: 3,
          max_gram: 3,
          token_chars: ['letter', 'digit']
        }
      }
    } } do
    mapping do
      indexes :title, type: 'text' do
        indexes :keyword, analyzer: 'keyword'
        indexes :pattern, analyzer: 'pattern'
        indexes :trigram, analyzer: 'trigram'
      end
    end
  end
end

# Create example records
#
Article.delete_all
Article.create title: 'Foo'
Article.create title: 'Foo-Bar'
Article.create title: 'Foo_Bar_Bazooka'
Article.create title: 'Foo.Bar'

# Index records
#
errors = Article.import force: true, refresh: true, return: 'errors'
puts "[!] Errors importing records: #{errors.map { |d| d['index']['error'] }.join(', ')}".ansi(:red) && exit(1) unless errors.empty?

puts '', '-'*80

puts "Fulltext analyzer [Foo_Bar_1_Bazooka]".ansi(:bold),
     "Tokens: " +
     Article.__elasticsearch__.client.indices
      .analyze(index: Article.index_name, body: { field: 'title', text: 'Foo_Bar_1_Bazooka' })['tokens']
      .map { |d| "[#{d['token']}]" }.join(' '),
    "\n"

puts "Keyword analyzer [Foo_Bar_1_Bazooka]".ansi(:bold),
     "Tokens: " +
     Article.__elasticsearch__.client.indices
      .analyze(index: Article.index_name, body: { field: 'title.keyword', text: 'Foo_Bar_1_Bazooka' })['tokens']
      .map { |d| "[#{d['token']}]" }.join(' '),
     "\n"

puts "Pattern analyzer [Foo_Bar_1_Bazooka]".ansi(:bold),
     "Tokens: " +
     Article.__elasticsearch__.client.indices
      .analyze(index: Article.index_name, body: { field: 'title.pattern', text: 'Foo_Bar_1_Bazooka' })['tokens']
      .map { |d| "[#{d['token']}]" }.join(' '),
     "\n"

puts "Trigram analyzer [Foo_Bar_1_Bazooka]".ansi(:bold),
     "Tokens: " +
     Article.__elasticsearch__.client.indices
      .analyze(index: Article.index_name, body: { field: 'title.trigram', text: 'Foo_Bar_1_Bazooka' })['tokens']
      .map { |d| "[#{d['token']}]" }.join(' '),
     "\n"

puts '', '-'*80

response = Article.search query: { match: { 'title' => 'foo' } } ;

puts "Search for 'foo'".ansi(:bold),
     "#{response.response.hits.total} matches: " +
     response.records.map { |d| d.title }.join(', '),
     "\n"

puts '', '-'*80

response = Article.search query: { match: { 'title.pattern' => 'foo' } } ;

puts "Pattern search for 'foo'".ansi(:bold),
     "#{response.response.hits.total} matches: " +
     response.records.map { |d| d.title }.join(', '),
     "\n"

puts '', '-'*80

response = Article.search query: { match: { 'title.trigram' => 'zoo' } } ;

puts "Trigram search for 'zoo'".ansi(:bold),
     "#{response.response.hits.total} matches: " +
     response.records.map { |d| d.title }.join(', '),
     "\n"

puts '', '-'*80


require 'pry'; binding.pry;
