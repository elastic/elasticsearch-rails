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

describe Elasticsearch::Model::Searching::ClassMethods do

  before(:all) do
    class ::DummySearchingModel
      extend Elasticsearch::Model::Searching::ClassMethods

      def self.index_name;    'foo'; end
      def self.document_type; 'bar'; end
    end
  end

  after(:all) do
    remove_classes(DummySearchingModel)
  end

  it 'has the search method' do
    expect(DummySearchingModel).to respond_to(:search)
  end

  describe '#search' do

    let(:response) do
      double('search', execute!: { 'hits' => {'hits' => [ {'_id' => 2 }, {'_id' => 1 } ]} })
    end

    before do
      expect(Elasticsearch::Model::Searching::SearchRequest).to receive(:new).with(DummySearchingModel, 'foo', { default_operator: 'AND' }).and_return(response)
    end

    it 'creates a search object' do
      expect(DummySearchingModel.search('foo', default_operator: 'AND')).to be_a(Elasticsearch::Model::Response::Response)
    end
  end

  describe 'lazy execution' do

    let(:response) do
      double('search').tap do |r|
        expect(r).to receive(:execute!).never
      end
    end

    it 'does not execute the search until the results are accessed' do
      DummySearchingModel.search('foo')
    end
  end
end
