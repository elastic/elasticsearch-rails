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

class Post < ActiveRecord::Base
  include Searchable

  has_and_belongs_to_many :categories, after_add:    [ lambda { |a,c| a.__elasticsearch__.index_document } ],
                          after_remove: [ lambda { |a,c| a.__elasticsearch__.index_document } ]
  has_many                :authorships
  has_many                :authors, through: :authorships,
                          after_add: [ lambda { |a,c| a.__elasticsearch__.index_document } ],
                          after_remove: [ lambda { |a,c| a.__elasticsearch__.index_document } ]
  has_many                :comments, after_add:    [ lambda { |a,c| a.__elasticsearch__.index_document } ],
                          after_remove: [ lambda { |a,c| a.__elasticsearch__.index_document } ]

  after_touch() { __elasticsearch__.index_document }
end
