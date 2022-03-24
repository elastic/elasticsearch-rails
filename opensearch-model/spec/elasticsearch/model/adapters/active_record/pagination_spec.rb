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

describe 'Elasticsearch::Model::Adapter::ActiveRecord Pagination' do

  before(:all) do
    ActiveRecord::Schema.define(:version => 1) do
      create_table ArticleForPagination.table_name do |t|
        t.string   :title
        t.datetime :created_at, :default => 'NOW()'
        t.boolean  :published
      end
    end

    Kaminari::Hooks.init if defined?(Kaminari::Hooks)

    ArticleForPagination.__elasticsearch__.create_index! force: true

    68.times do |i|
      ArticleForPagination.create! title: "Test #{i}", published: (i % 2 == 0)
    end

    ArticleForPagination.import
    ArticleForPagination.__elasticsearch__.refresh_index!
  end

  context 'when no other page is specified' do

    let(:records) do
      ArticleForPagination.search('title:test').page(1).records
    end

    describe '#size' do

      it 'returns the correct size' do
        expect(records.size).to eq(25)
      end
    end

    describe '#current_page' do

      it 'returns the correct current page' do
        expect(records.current_page).to eq(1)
      end
    end

    describe '#prev_page' do

      it 'returns the correct previous page' do
        expect(records.prev_page).to be_nil
      end
    end

    describe '#next_page' do

      it 'returns the correct next page' do
        expect(records.next_page).to eq(2)
      end
    end

    describe '#total_pages' do

      it 'returns the correct total pages' do
        expect(records.total_pages).to eq(3)
      end
    end

    describe '#first_page?' do

      it 'returns the correct first page' do
        expect(records.first_page?).to be(true)
      end
    end

    describe '#last_page?' do

      it 'returns the correct last page' do
        expect(records.last_page?).to be(false)
      end
    end

    describe '#out_of_range?' do

      it 'returns whether the pagination is out of range' do
        expect(records.out_of_range?).to be(false)
      end
    end
  end

  context 'when a specific page is specified' do

    let(:records) do
      ArticleForPagination.search('title:test').page(2).records
    end

    describe '#size' do

      it 'returns the correct size' do
        expect(records.size).to eq(25)
      end
    end

    describe '#current_page' do

      it 'returns the correct current page' do
        expect(records.current_page).to eq(2)
      end
    end

    describe '#prev_page' do

      it 'returns the correct previous page' do
        expect(records.prev_page).to eq(1)
      end
    end

    describe '#next_page' do

      it 'returns the correct next page' do
        expect(records.next_page).to eq(3)
      end
    end

    describe '#total_pages' do

      it 'returns the correct total pages' do
        expect(records.total_pages).to eq(3)
      end
    end

    describe '#first_page?' do

      it 'returns the correct first page' do
        expect(records.first_page?).to be(false)
      end
    end

    describe '#last_page?' do

      it 'returns the correct last page' do
        expect(records.last_page?).to be(false)
      end
    end

    describe '#out_of_range?' do

      it 'returns whether the pagination is out of range' do
        expect(records.out_of_range?).to be(false)
      end
    end
  end

  context 'when a the last page is specified' do

    let(:records) do
      ArticleForPagination.search('title:test').page(3).records
    end

    describe '#size' do

      it 'returns the correct size' do
        expect(records.size).to eq(18)
      end
    end

    describe '#current_page' do

      it 'returns the correct current page' do
        expect(records.current_page).to eq(3)
      end
    end

    describe '#prev_page' do

      it 'returns the correct previous page' do
        expect(records.prev_page).to eq(2)
      end
    end

    describe '#next_page' do

      it 'returns the correct next page' do
        expect(records.next_page).to be_nil
      end
    end

    describe '#total_pages' do

      it 'returns the correct total pages' do
        expect(records.total_pages).to eq(3)
      end
    end

    describe '#first_page?' do

      it 'returns the correct first page' do
        expect(records.first_page?).to be(false)
      end
    end

    describe '#last_page?' do

      it 'returns the correct last page' do
        expect(records.last_page?).to be(true)
      end
    end

    describe '#out_of_range?' do

      it 'returns whether the pagination is out of range' do
        expect(records.out_of_range?).to be(false)
      end
    end
  end

  context 'when an invalid page is specified' do

    let(:records) do
      ArticleForPagination.search('title:test').page(6).records
    end

    describe '#size' do

      it 'returns the correct size' do
        expect(records.size).to eq(0)
      end
    end

    describe '#current_page' do

      it 'returns the correct current page' do
        expect(records.current_page).to eq(6)
      end
    end

    describe '#next_page' do

      it 'returns the correct next page' do
        expect(records.next_page).to be_nil
      end
    end

    describe '#total_pages' do

      it 'returns the correct total pages' do
        expect(records.total_pages).to eq(3)
      end
    end

    describe '#first_page?' do

      it 'returns the correct first page' do
        expect(records.first_page?).to be(false)
      end
    end

    describe '#last_page?' do

      it 'returns whether it is the last page', if: !(Kaminari::VERSION < '1') do
        expect(records.last_page?).to be(false)
      end

      it 'returns whether it is the last page', if: Kaminari::VERSION < '1' do
        expect(records.last_page?).to be(true) # Kaminari returns current_page >= total_pages in version < 1.0
      end
    end

    describe '#out_of_range?' do

      it 'returns whether the pagination is out of range' do
        expect(records.out_of_range?).to be(true)
      end
    end
  end

  context 'when a scope is also specified' do

    let(:records) do
      ArticleForPagination.search('title:test').page(2).records.published
    end

    describe '#size' do

      it 'returns the correct size' do
        expect(records.size).to eq(12)
      end
    end
  end

  context 'when a sorting is specified' do

    let(:search) do
      ArticleForPagination.search({ query: { match: { title: 'test' } }, sort: [ { id: 'desc' } ] })
    end

    it 'applies the sort' do
      expect(search.page(2).records.first.id).to eq(43)
      expect(search.page(3).records.first.id).to eq(18)
      expect(search.page(2).per(5).records.first.id).to eq(63)
    end
  end

  context 'when the model has a specific default per page set' do

    around do |example|
      original_default = ArticleForPagination.instance_variable_get(:@_default_per_page)
      ArticleForPagination.paginates_per 50
      example.run
      ArticleForPagination.paginates_per original_default
    end

    it 'uses the default per page setting' do
      expect(ArticleForPagination.search('*').page(1).records.size).to eq(50)
    end
  end
end
