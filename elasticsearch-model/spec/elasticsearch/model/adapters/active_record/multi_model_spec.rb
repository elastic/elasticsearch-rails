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

describe 'Elasticsearch::Model::Adapter::ActiveRecord MultiModel' do

  before(:all) do
    ActiveRecord::Schema.define do
      create_table Episode.table_name do |t|
        t.string :name
        t.datetime :created_at, :default => 'NOW()'
      end

      create_table Series.table_name do |t|
        t.string :name
        t.datetime :created_at, :default => 'NOW()'
      end
    end
  end

  before do
    models = [ Episode, Series ]
    clear_tables(models)
    models.each do |model|
      model.__elasticsearch__.create_index! force: true
      model.create name: "The #{model.name}"
      model.create name: "A great #{model.name}"
      model.create name: "The greatest #{model.name}"
      model.__elasticsearch__.refresh_index!
    end
  end

  after do
    clear_indices(Episode, Series)
    clear_tables(Episode, Series)
  end

  context 'when the search is across multimodels' do

    let(:search_result) do
      Elasticsearch::Model.search(%q<"The greatest Episode"^2 OR "The greatest Series">, [Series, Episode])
    end

    it 'executes the search across models' do
      expect(search_result.results.size).to eq(2)
      expect(search_result.records.size).to eq(2)
    end

    describe '#results' do

      it 'returns an instance of Elasticsearch::Model::Response::Result' do
        expect(search_result.results[0]).to be_a(Elasticsearch::Model::Response::Result)
        expect(search_result.results[1]).to be_a(Elasticsearch::Model::Response::Result)
      end

      it 'returns the correct model instance' do
        expect(search_result.results[0].name).to eq('The greatest Episode')
        expect(search_result.results[1].name).to eq('The greatest Series')
      end

      it 'provides access to the results' do
        expect(search_result.results[0].name).to eq('The greatest Episode')
        expect(search_result.results[0].name?).to be(true)
        expect(search_result.results[0].boo?).to be(false)

        expect(search_result.results[1].name).to eq('The greatest Series')
        expect(search_result.results[1].name?).to be(true)
        expect(search_result.results[1].boo?).to be(false)
      end
    end

    describe '#records' do

      it 'returns an instance of Elasticsearch::Model::Response::Result' do
        expect(search_result.records[0]).to be_a(Episode)
        expect(search_result.records[1]).to be_a(Series)
      end

      it 'returns the correct model instance' do
        expect(search_result.records[0].name).to eq('The greatest Episode')
        expect(search_result.records[1].name).to eq('The greatest Series')
      end

      context 'when the data store is changed' do

        before do
          Series.find_by_name("The greatest Series").delete
          Series.__elasticsearch__.refresh_index!
        end

        it 'only returns matching records' do
          expect(search_result.results.size).to eq(2)
          expect(search_result.records.size).to eq(1  )
          expect(search_result.records[0].name).to eq('The greatest Episode')
        end
      end
    end

    describe 'pagination' do

      let(:search_result) do
        Elasticsearch::Model.search('series OR episode', [Series, Episode])
      end

      it 'properly paginates the results' do
        expect(search_result.page(1).per(3).results.size).to eq(3)
        expect(search_result.page(2).per(3).results.size).to eq(3)
        expect(search_result.page(3).per(3).results.size).to eq(0)
      end
    end
  end
end
