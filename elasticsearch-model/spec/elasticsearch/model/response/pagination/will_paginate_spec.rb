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

require 'spec_helper'

describe 'Elasticsearch::Model::Response::Response WillPaginate' do

  before(:all) do
    class ModelClass
      def self.index_name;    'foo'; end
      def self.document_type; 'bar'; end

      def self.per_page
        33
      end
    end

    # Subclass Response so we can include WillPaginate module without conflicts with Kaminari.
    class WillPaginateResponse < Elasticsearch::Model::Response::Response
      include Elasticsearch::Model::Response::Pagination::WillPaginate
    end
  end

  after(:all) do
    remove_classes(ModelClass, WillPaginateResponse)
  end

  let(:response_document) do
    { 'took' => '5', 'timed_out' => false, '_shards' => {'one' => 'OK'},
      'hits' => { 'total' => 100, 'hits' => (1..100).to_a.map { |i| { _id: i } } } }
  end

  let(:search) do
    Elasticsearch::Model::Searching::SearchRequest.new(model, '*')
  end

  let(:response) do
    allow(model).to receive(:client).and_return(client)
    WillPaginateResponse.new(model, search, response_document).tap do |resp|
      allow(resp).to receive(:client).and_return(client)
    end
  end

  let(:client) do
    double('client')
  end

  shared_examples_for 'a search request that can be paginated' do

    describe '#offset' do

      context 'when per_page and page are set' do

        before do
          response.per_page(3).page(3)
        end

        it 'sets the correct offset' do
          expect(response.offset).to eq(6)
        end
      end
    end

    describe '#length' do

      context 'when per_page and page are set' do

        before do
          response.per_page(3).page(3)
        end

        it 'sets the correct offset' do
          expect(response.length).to eq(3)
        end
      end
    end

    describe '#paginate' do

      context 'when there are no settings' do

        context 'when page is set to nil' do

          before do
            response.paginate(page: nil)
          end

          it 'uses the defaults' do
            expect(response.search.definition[:size]).to eq(default_per_page)
            expect(response.search.definition[:from]).to eq(0)
          end
        end

        context 'when page is set to a value' do

          before do
            response.paginate(page: 2)
          end

          it 'uses the defaults' do
            expect(response.search.definition[:size]).to eq(default_per_page)
            expect(response.search.definition[:from]).to eq(default_per_page)
          end
        end

        context 'when a custom page and per_page is set' do

          before do
            response.paginate(page: 3, per_page: 9)
          end

          it 'uses the custom values' do
            expect(response.search.definition[:size]).to eq(9)
            expect(response.search.definition[:from]).to eq(18)
          end
        end

        context 'fall back to first page if invalid value is provided' do

          before do
            response.paginate(page: -1)
          end

          it 'uses the custom values' do
            expect(response.search.definition[:size]).to eq(default_per_page)
            expect(response.search.definition[:from]).to eq(0)
          end
        end
      end
    end

    describe '#page' do

      context 'when a value is provided for page' do

        before do
          response.page(5)
        end

        it 'calculates the correct :size and :from' do
          expect(response.search.definition[:size]).to eq(default_per_page)
          expect(response.search.definition[:from]).to eq(default_per_page * 4)
        end
      end

      context 'when a value is provided for page and per_page' do

        before do
          response.page(5).per_page(3)
        end

        it 'calculates the correct :size and :from' do
          expect(response.search.definition[:size]).to eq(3)
          expect(response.search.definition[:from]).to eq(12)
        end
      end

      context 'when a value is provided for per_page and page' do

        before do
          response.per_page(3).page(5)
        end

        it 'calculates the correct :size and :from' do
          expect(response.search.definition[:size]).to eq(3)
          expect(response.search.definition[:from]).to eq(12)
        end
      end
    end

    describe '#current_page' do

      context 'when no values are set' do

        before do
          response.paginate({})
        end

        it 'returns the first page' do
          expect(response.current_page).to eq(1)
        end
      end

      context 'when values are provided for per_page and page' do

        before do
          response.paginate(page: 3, per_page: 9)
        end

        it 'calculates the correct current page' do
          expect(response.current_page).to eq(3)
        end
      end

      context 'when #paginate has not been called on the response' do

        it 'returns nil' do
          expect(response.current_page).to be_nil
        end
      end
    end

    describe '#per_page' do

      context 'when a value is set via the #paginate method' do

        before do
          response.paginate(per_page: 8)
        end

        it 'returns the per_page value' do
          expect(response.per_page).to eq(8)
        end
      end

      context 'when a value is set via the #per_page method' do

        before do
          response.per_page(8)
        end

        it 'returns the per_page value' do
          expect(response.per_page).to eq(8)
        end
      end
    end

    describe '#total_entries' do

      before do
        allow(response).to receive(:results).and_return(double('results', total: 100))
      end

      it 'returns the total results' do
        expect(response.total_entries).to eq(100)
      end
    end
  end

  context 'when the model is a single one' do

    let(:model) do
      ModelClass
    end

    let(:default_per_page) do
      33
    end

    it_behaves_like 'a search request that can be paginated'
  end

  context 'when the model is a multimodel' do

    let(:model) do
      Elasticsearch::Model::Multimodel.new(ModelClass)
    end

    let(:default_per_page) do
      ::WillPaginate.per_page
    end

    it_behaves_like 'a search request that can be paginated'
  end
end
