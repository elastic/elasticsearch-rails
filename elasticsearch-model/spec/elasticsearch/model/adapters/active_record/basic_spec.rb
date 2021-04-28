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

describe Elasticsearch::Model::Adapter::ActiveRecord do

  context 'when a document_type is not defined for the Model' do

    before do
      ActiveRecord::Schema.define(:version => 1) do
        create_table :article_no_types do |t|
          t.string   :title
          t.string   :body
          t.integer  :clicks, :default => 0
          t.datetime :created_at, :default => 'NOW()'
        end
      end

      ArticleNoType.delete_all
      ArticleNoType.__elasticsearch__.create_index!(force: true)

      ArticleNoType.create!(title: 'Test', body: '', clicks: 1)
      ArticleNoType.create!(title: 'Testing Coding', body: '', clicks: 2)
      ArticleNoType.create!(title: 'Coding', body: '', clicks: 3)

      ArticleNoType.__elasticsearch__.refresh_index!
    end

    describe 'indexing a document' do

      let(:search_result) do
        ArticleNoType.search('title:test')
      end

      it 'allows searching for documents' do
        expect(search_result.results.size).to be(2)
        expect(search_result.records.size).to be(2)
      end
    end
  end

  context 'when a document_type is defined for the Model' do

    before(:all) do
      ActiveRecord::Schema.define(:version => 1) do
        create_table :articles do |t|
          t.string   :title
          t.string   :body
          t.integer  :clicks, :default => 0
          t.datetime :created_at, :default => 'NOW()'
        end
      end

      Article.delete_all
      Article.__elasticsearch__.create_index!(force: true, include_type_name: true)

      Article.create!(title: 'Test', body: '', clicks: 1)
      Article.create!(title: 'Testing Coding', body: '', clicks: 2)
      Article.create!(title: 'Coding', body: '', clicks: 3)

      Article.__elasticsearch__.refresh_index!
    end

    describe 'indexing a document' do

      let(:search_result) do
        Article.search('title:test')
      end

      it 'allows searching for documents' do
        expect(search_result.results.size).to be(2)
        expect(search_result.records.size).to be(2)
      end
    end

    describe '#results' do

      let(:search_result) do
        Article.search('title:test')
      end

      it 'returns an instance of Response::Result' do
        expect(search_result.results.first).to be_a(Elasticsearch::Model::Response::Result)
      end

      it 'prooperly loads the document' do
        expect(search_result.results.first.title).to eq('Test')
      end

      context 'when the result contains other data' do

        let(:search_result) do
          Article.search(query: { match: { title: 'test' } }, highlight: { fields: { title: {} } })
        end

        it 'allows access to the Elasticsearch result' do
          expect(search_result.results.first.title).to eq('Test')
          expect(search_result.results.first.title?).to be(true)
          expect(search_result.results.first.boo?).to be(false)
          expect(search_result.results.first.highlight?).to be(true)
          expect(search_result.results.first.highlight.title?).to be(true)
          expect(search_result.results.first.highlight.boo?).to be(false)
        end
      end
    end

    describe '#records' do

      let(:search_result) do
        Article.search('title:test')
      end

      it 'returns an instance of the model' do
        expect(search_result.records.first).to be_a(Article)
      end

      it 'prooperly loads the document' do
        expect(search_result.records.first.title).to eq('Test')
      end
    end

    describe 'Enumerable' do

      let(:search_result) do
        Article.search('title:test')
      end

      it 'allows iteration over results' do
        expect(search_result.results.map(&:_id)).to eq(['1', '2'])
      end

      it 'allows iteration over records' do
        expect(search_result.records.map(&:id)).to eq([1, 2])
      end
    end

    describe '#id' do

      let(:search_result) do
        Article.search('title:test')
      end

      it 'returns the id' do
        expect(search_result.results.first.id).to eq('1')
      end
    end

    describe '#id' do

      let(:search_result) do
        Article.search('title:test')
      end

      it 'returns the type' do
        expect(search_result.results.first.type).to eq('article')
      end
    end

    describe '#each_with_hit' do

      let(:search_result) do
        Article.search('title:test')
      end

      it 'returns the record with the Elasticsearch hit' do
        search_result.records.each_with_hit do |r, h|
          expect(h._score).not_to be_nil
          expect(h._source.title).not_to be_nil
        end
      end
    end

    describe 'search results order' do

      let(:search_result) do
        Article.search(query: { match: { title: 'code' }}, sort: { clicks: :desc })
      end

      it 'preserves the search results order when accessing a single record' do
        expect(search_result.records[0].clicks).to be(3)
        expect(search_result.records[1].clicks).to be(2)
        expect(search_result.records.first).to eq(search_result.records[0])
      end

      it 'preserves the search results order for the list of records' do
        search_result.records.each_with_hit do |r, h|
          expect(r.id.to_s).to eq(h._id)
        end

        search_result.records.map_with_hit do |r, h|
          expect(r.id.to_s).to eq(h._id)
        end
      end
    end

    describe 'a paged collection' do

      let(:search_result) do
        Article.search(query: { match: { title: { query: 'test' } } },
                       size: 2,
                       from: 1)
      end

      it 'applies the paged options to the search' do
        expect(search_result.results.size).to eq(1)
        expect(search_result.results.first.title).to eq('Testing Coding')
        expect(search_result.records.size).to eq(1)
        expect(search_result.records.first.title).to eq('Testing Coding')
      end
    end

    describe '#destroy' do

      before do
        Article.create!(title: 'destroy', body: '', clicks: 1)
        Article.__elasticsearch__.refresh_index!
        Article.where(title: 'destroy').first.destroy

        Article.__elasticsearch__.refresh_index!
      end

      let(:search_result) do
        Article.search('title:test')
      end

      it 'removes the document from the index' do
        expect(Article.count).to eq(3)
        expect(search_result.results.size).to eq(2)
        expect(search_result.records.size).to eq(2)
      end
    end

    describe 'full document updates' do

      before do
        article = Article.create!(title: 'update', body: '', clicks: 1)
        Article.__elasticsearch__.refresh_index!
        article.title = 'Writing'
        article.save

        Article.__elasticsearch__.refresh_index!
      end

      let(:search_result) do
        Article.search('title:write')
      end

      it 'applies the update' do
        expect(search_result.results.size).to eq(1)
        expect(search_result.records.size).to eq(1)
      end
    end

    describe 'attribute updates' do

      before do
        article = Article.create!(title: 'update', body: '', clicks: 1)
        Article.__elasticsearch__.refresh_index!
        article.title = 'special'
        article.save

        Article.__elasticsearch__.refresh_index!
      end

      let(:search_result) do
        Article.search('title:special')
      end

      it 'applies the update' do
        expect(search_result.results.size).to eq(1)
        expect(search_result.records.size).to eq(1)
      end
    end

    describe '#save' do

      before do
        article = Article.create!(title: 'save', body: '', clicks: 1)

        ActiveRecord::Base.transaction do
          article.body = 'dummy'
          article.save

          article.title = 'special'
          article.save
        end

        article.__elasticsearch__.update_document
        Article.__elasticsearch__.refresh_index!
      end

      let(:search_result) do
        Article.search('body:dummy')
      end

      it 'applies the save' do
        expect(search_result.results.size).to eq(1)
        expect(search_result.records.size).to eq(1)
      end
    end

    describe 'a DSL search' do

      let(:search_result) do
        Article.search(query: { match: { title: { query: 'test' } } })
      end

      it 'returns the results' do
        expect(search_result.results.size).to eq(2)
        expect(search_result.records.size).to eq(2)
      end
    end

    describe 'chaining SQL queries on response.records' do

      let(:search_result) do
        Article.search(query: { match: { title: { query: 'test' } } })
      end

      it 'executes the SQL request with the chained query criteria' do
        expect(search_result.records.size).to eq(2)
        expect(search_result.records.where(title: 'Test').size).to eq(1)
        expect(search_result.records.where(title: 'Test').first.title).to eq('Test')
      end
    end

    describe 'ordering of SQL queries' do

      context 'when order is called on the ActiveRecord query' do

        let(:search_result) do
          Article.search query: { match: { title: { query: 'test' } } }
        end

        it 'allows the SQL query to be ordered independent of the Elasticsearch results order', unless: active_record_at_least_4? do
          expect(search_result.records.order('title DESC').first.title).to eq('Testing Coding')
          expect(search_result.records.order('title DESC')[0].title).to eq('Testing Coding')
        end

        it 'allows the SQL query to be ordered independent of the Elasticsearch results order', if: active_record_at_least_4? do
          expect(search_result.records.order(title: :desc).first.title).to eq('Testing Coding')
          expect(search_result.records.order(title: :desc)[0].title).to eq('Testing Coding')
        end
      end

      context 'when more methods are chained on the ActiveRecord query' do

        let(:search_result) do
          Article.search query: {match: {title: {query: 'test'}}}
        end

        it 'allows the SQL query to be ordered independent of the Elasticsearch results order', if: active_record_at_least_4? do
          expect(search_result.records.distinct.order(title: :desc).first.title).to eq('Testing Coding')
          expect(search_result.records.distinct.order(title: :desc)[0].title).to eq('Testing Coding')
        end
      end
    end

    describe 'access to the response via methods' do

      let(:search_result) do
        Article.search(query: { match: { title: { query: 'test' } } },
                       aggregations: {
                           dates: { date_histogram: { field: 'created_at', interval: 'hour' } },
                           clicks: { global: {}, aggregations: { min: { min: { field: 'clicks' } } } }
                       },
                       suggest: { text: 'tezt', title: { term: { field: 'title', suggest_mode: 'always' } } })
      end

      it 'allows document keys to be access via methods' do
        expect(search_result.aggregations.dates.buckets.first.doc_count).to eq(2)
        expect(search_result.aggregations.clicks.doc_count).to eq(6)
        expect(search_result.aggregations.clicks.min.value).to eq(1.0)
        expect(search_result.aggregations.clicks.max).to be_nil
        expect(search_result.suggestions.title.first.options.size).to eq(1)
        expect(search_result.suggestions.terms).to eq(['test'])
      end
    end
  end
end
