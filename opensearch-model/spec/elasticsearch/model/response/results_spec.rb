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

describe Elasticsearch::Model::Response::Results do

  before(:all) do
    class OriginClass
      def self.index_name;    'foo'; end
      def self.document_type; 'bar'; end
    end
  end

  after(:all) do
    remove_classes(OriginClass)
  end

  let(:response_document) do
    { 'hits' => { 'total' => 123, 'max_score' => 456, 'hits' => [{'foo' => 'bar'}] } }
  end

  let(:search) do
    Elasticsearch::Model::Searching::SearchRequest.new(OriginClass, '*').tap do |request|
      allow(request).to receive(:execute!).and_return(response_document)
    end
  end

  let(:response) do
    Elasticsearch::Model::Response::Response.new(OriginClass, search)
  end

  let(:results) do
    response.results
  end

  let(:records) do
    response.records
  end

  describe '#results' do

    it 'provides access to the results' do
      expect(results.results.size).to be(1)
      expect(results.results.first.foo).to eq('bar')
    end
  end

  describe 'Enumerable' do

    it 'deletebates enumerable methods to the results' do
      expect(results.empty?).to be(false)
      expect(results.first.foo).to eq('bar')
    end
  end

  describe '#raw_response' do

    it 'returns the raw response document' do
      expect(response.raw_response).to eq(response_document)
    end
  end

  describe '#records' do

    it 'provides access to the records' do
      expect(results.records.size).to be(results.results.size)
      expect(results.records.first.foo).to eq(results.results.first.foo)
    end
  end
end
