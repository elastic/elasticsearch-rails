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

Elasticsearch::Model.client.transport.transport.logger = ActiveSupport::Logger.new(STDOUT)
Elasticsearch::Model.client.transport.transport.logger.formatter = lambda { |s, d, p, m| "#{m.ansi(:faint)}\n" }

class Article < ActiveRecord::Base
  include Elasticsearch::Model

  settings index: {
    number_of_shards: 1,
    number_of_replicas: 0,
    analysis: {
      analyzer: {
        pattern: {
          type: 'pattern',
          pattern: "\\s|_|-|\\.",
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
      indexes :title, type: 'text', analyzer: 'english' do
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

puts "English analyzer [Foo_Bar_1_Bazooka]".ansi(:bold),
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

puts "English search for 'foo'".ansi(:bold),
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
