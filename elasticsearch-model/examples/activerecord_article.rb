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

# ActiveRecord and Elasticsearch
# ==============================
#
# https://github.com/rails/rails/tree/master/activerecord

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'pry'
Pry.config.history.file = File.expand_path('../../tmp/elasticsearch_development.pry', __FILE__)

require 'logger'
require 'ansi/core'
require 'active_record'
require 'kaminari'

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

Kaminari::Hooks.init if defined?(Kaminari::Hooks) if defined?(Kaminari::Hooks)

class Article < ActiveRecord::Base
end

# Store data
#
Article.delete_all
Article.create title: 'Foo'
Article.create title: 'Bar'
Article.create title: 'Foo Foo'

# Index data
#
client = Elasticsearch::Client.new log:true

# client.indices.delete index: 'articles' rescue nil
# client.indices.create index: 'articles', body: { mappings: { article: { dynamic: 'strict' }, properties: {} } }

client.indices.delete index: 'articles' rescue nil
client.bulk index: 'articles',
            type:  'article',
            body:  Article.all.as_json.map { |a| { index: { _id: a.delete('id'), data: a } } },
            refresh: true

# Extend the model with Elasticsearch support
#
Article.__send__ :include, Elasticsearch::Model
# Article.__send__ :include, Elasticsearch::Model::Callbacks

# ActiveRecord::Base.logger.silence do
#   10_000.times do |i|
#     Article.create title: "Foo #{i}"
#   end
# end

puts '', '-'*Pry::Terminal.width!

Elasticsearch::Model.client = Elasticsearch::Client.new log: true

response = Article.search 'foo';

p response.size
p response.results.size
p response.records.size

Pry.start(binding, prompt: lambda { |obj, nest_level, _| '> ' },
                   input: StringIO.new('response.records.to_a'),
                   quiet: true)
