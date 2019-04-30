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

module ParentChildSearchable
  INDEX_NAME = 'questions_and_answers'.freeze
  JOIN = 'join'.freeze

  def create_index!(options={})
    client = Question.__elasticsearch__.client
    client.indices.delete index: INDEX_NAME rescue nil if options.delete(:force)

    settings = Question.settings.to_hash.merge Answer.settings.to_hash
    mapping_properties = { join_field: { type: JOIN,
                                         relations: { Question::JOIN_TYPE => Answer::JOIN_TYPE } } }

    merged_properties = mapping_properties.merge(Question.mappings.to_hash[:doc][:properties]).merge(
        Answer.mappings.to_hash[:doc][:properties])
    mappings = { doc: { properties: merged_properties }}

    client.indices.create({ index: INDEX_NAME,
                            body: {
                              settings: settings.to_hash,
                              mappings: mappings } }.merge(options))
  end

  extend self
end
