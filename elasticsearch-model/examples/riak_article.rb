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

# Riak and Elasticsearch
# ======================
#
# https://github.com/basho-labs/ripple

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'pry'
Pry.config.history.file = File.expand_path('../../tmp/elasticsearch_development.pry', __FILE__)

require 'logger'
require 'ripple'

require 'elasticsearch/model'

# Documents are stored as JSON objects in Riak but have rich
# semantics, including validations and associations.
class Article
  include Ripple::Document

  property :title,        String
  property :published_at, Time,   :default => proc { Time.now }
end

# Extend the model with Elasticsearch support
#
Article.__send__ :include, Elasticsearch::Model

# Create documents in Riak
#
Article.destroy_all
Article.create id: '1', title: 'Foo'
Article.create id: '2', title: 'Bar'
Article.create id: '3', title: 'Foo Foo'

# Index data into Elasticsearch
#
client = Elasticsearch::Client.new log:true

client.indices.delete index: 'articles' rescue nil
client.bulk index: 'articles',
            type:  'article',
            body:  Article.all.map { |a|
                     { index: { _id: a.key, data: JSON.parse(a.robject.raw_data) } }
                   }.as_json,
            refresh: true

response = Article.search 'foo';

Pry.start(binding, prompt: lambda { |obj, nest_level, _| '> ' },
                   input: StringIO.new('response.records.to_a'),
                   quiet: true)
