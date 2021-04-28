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

# Couchbase and Elasticsearch
# ===========================
#
# https://github.com/couchbase/couchbase-ruby-model

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'pry'
Pry.config.history.file = File.expand_path('../../tmp/elasticsearch_development.pry', __FILE__)

require 'logger'
require 'couchbase/model'

require 'elasticsearch/model'

# Documents are stored as JSON objects in Riak but have rich
# semantics, including validations and associations.
class Article < Couchbase::Model
  attribute :title
  attribute :published_at

  # view :all, :limit => 10, :descending => true
  # TODO: Implement view a la
  # bucket.save_design_doc <<-JSON
  #   {
  #   "_id": "_design/article",
  #   "language": "javascript",
  #   "views": {
  #     "all": {
  #       "map": "function(doc, meta) { emit(doc.id, doc.title); }"
  #     }
  #   }
  # }
  # JSON

end

# Extend the model with Elasticsearch support
#
Article.__send__ :extend, Elasticsearch::Model::Client::ClassMethods
Article.__send__ :extend, Elasticsearch::Model::Searching::ClassMethods
Article.__send__ :extend, Elasticsearch::Model::Naming::ClassMethods

# Create documents in Riak
#
Article.create id: '1', title: 'Foo'      rescue nil
Article.create id: '2', title: 'Bar'      rescue nil
Article.create id: '3', title: 'Foo Foo'  rescue nil

# Index data into Elasticsearch
#
client = Elasticsearch::Client.new log:true

client.indices.delete index: 'articles' rescue nil
client.bulk index: 'articles',
            type:  'article',
            body:  Article.find(['1', '2', '3']).map { |a|
                     { index: { _id: a.id, data: a.attributes } }
                   },
            refresh: true

response = Article.search 'foo', index: 'articles', type: 'article';

Pry.start(binding, prompt: lambda { |obj, nest_level, _| '> ' },
                   input: StringIO.new('response.records.to_a'),
                   quiet: true)
