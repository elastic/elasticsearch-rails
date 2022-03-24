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

class Answer < ActiveRecord::Base
  include Elasticsearch::Model

  belongs_to :question

  JOIN_TYPE = 'answer'.freeze

  index_name 'questions_and_answers'.freeze
  document_type 'doc'.freeze

  before_create :randomize_id

  def randomize_id
    begin
      self.id = SecureRandom.random_number(1_000_000)
    end while Answer.where(id: self.id).exists?
  end

  mapping do
    indexes :text
    indexes :author
  end

  def as_indexed_json(options={})
    # This line is necessary for differences between ActiveModel::Serializers::JSON#as_json versions
    json = as_json(options)[JOIN_TYPE] || as_json(options)
    json.merge(join_field: { name: JOIN_TYPE, parent: question_id })
  end

  after_commit lambda { __elasticsearch__.index_document(routing: (question_id || 1))  },  on: :create
  after_commit lambda { __elasticsearch__.update_document(routing: (question_id || 1)) },  on: :update
  after_commit lambda {__elasticsearch__.delete_document(routing: (question_id || 1)) },  on: :destroy
end
