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

# DataMapper and Elasticsearch
# ============================
#
# https://github.com/datamapper/dm-core
# https://github.com/datamapper/dm-active_model


$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'pry'
Pry.config.history.file = File.expand_path('../../tmp/elasticsearch_development.pry', __FILE__)

require 'logger'
require 'ansi/core'

require 'data_mapper'
require 'dm-active_model'

require 'active_support/all'

require 'elasticsearch/model'

DataMapper::Logger.new(STDOUT, :debug)
DataMapper.setup(:default, 'sqlite::memory:')

class Article
  include DataMapper::Resource

  property :id,           Serial
  property :title,        String
  property :published_at, DateTime
end

DataMapper.auto_migrate!
DataMapper.finalize

Article.create title: 'Foo'
Article.create title: 'Bar'
Article.create title: 'Foo Foo'

# Extend the model with Elasticsearch support
#
Article.__send__ :include, Elasticsearch::Model

# The DataMapper adapter
#
module DataMapperAdapter

  # Implement the interface for fetching records
  #
  module Records
    def records
      klass.all(id: ids)
    end

    # ...
  end

  module Callbacks
    def self.included(model)
      model.class_eval do
        after(:create) { __elasticsearch__.index_document  }
        after(:save) { __elasticsearch__.update_document }
        after(:destroy) { __elasticsearch__.delete_document }
      end
    end
  end
end

# Register the adapter
#
Elasticsearch::Model::Adapter.register(
  DataMapperAdapter,
  lambda { |klass| defined?(::DataMapper::Resource) and klass.ancestors.include?(::DataMapper::Resource) }
)

response = Article.search 'foo';

Pry.start(binding, prompt: lambda { |obj, nest_level, _| '> ' },
                   input: StringIO.new('response.records.to_a'),
                   quiet: true)
