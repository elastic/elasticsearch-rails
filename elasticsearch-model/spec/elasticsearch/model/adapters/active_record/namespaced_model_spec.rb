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

require 'spec_helper'

describe 'Elasticsearch::Model::Adapter::ActiveRecord Namespaced Model' do

  before(:all) do
    ActiveRecord::Schema.define(:version => 1) do
      create_table :books do |t|
        t.string   :title
      end
    end

    MyNamespace::Book.delete_all
    MyNamespace::Book.__elasticsearch__.create_index!(force: true, include_type_name: true)
    MyNamespace::Book.create!(title: 'Test')
    MyNamespace::Book.__elasticsearch__.refresh_index!
  end

  after do
    clear_indices(MyNamespace::Book)
    clear_tables(MyNamespace::Book)
  end

  context 'when the model is namespaced' do

    it 'has the proper index name' do
      expect(MyNamespace::Book.index_name).to eq('my_namespace-books')
    end

    it 'has the proper document type' do
      expect(MyNamespace::Book.document_type).to eq('book')
    end

    it 'saves the document into the index' do
      expect(MyNamespace::Book.search('title:test').results.size).to eq(1)
      expect(MyNamespace::Book.search('title:test').results.first.title).to eq('Test')
    end
  end
end
