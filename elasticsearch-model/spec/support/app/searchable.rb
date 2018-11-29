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

module Searchable
  extend ActiveSupport::Concern

  included do
    include Elasticsearch::Model
    include Elasticsearch::Model::Callbacks

    # Set up the mapping
    #
    settings index: { number_of_shards: 1, number_of_replicas: 0 } do
      mapping do
        indexes :title,      analyzer: 'snowball'
        indexes :created_at, type: 'date'

        indexes :authors do
          indexes :first_name
          indexes :last_name
            indexes :full_name, type: 'text' do
            indexes :raw, type: 'keyword'
          end
        end

        indexes :categories, type: 'keyword'

        indexes :comments, type: 'nested' do
          indexes :text
          indexes :author
        end
      end
    end

    # Customize the JSON serialization for Elasticsearch
    #
    def as_indexed_json(options={})
      {
          title: title,
          text:  text,
          categories: categories.map(&:title),
          authors:    authors.as_json(methods: [:full_name], only: [:full_name, :first_name, :last_name]),
          comments:   comments.as_json(only: [:text, :author])
      }
    end

    # Update document in the index after touch
    #
    after_touch() { __elasticsearch__.index_document }
  end
end
