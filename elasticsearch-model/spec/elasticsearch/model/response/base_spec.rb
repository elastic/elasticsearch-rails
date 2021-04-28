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

describe Elasticsearch::Model::Response::Base do

  before(:all) do
    class DummyBaseClass
      include Elasticsearch::Model::Response::Base
    end

    class OriginClass
      def self.index_name;    'foo'; end
      def self.document_type; 'bar'; end
    end
  end

  after(:all) do
    remove_classes(DummyBaseClass, OriginClass)
  end

  let(:response_document) do
    { 'hits' => { 'total' => 123, 'max_score' => 456, 'hits' => [] } }
  end

  let(:search) do
    Elasticsearch::Model::Searching::SearchRequest.new(OriginClass, '*').tap do |request|
      allow(request).to receive(:execute!).and_return(response_document)
    end
  end

  let(:response) do
    Elasticsearch::Model::Response::Response.new(OriginClass, search)
  end

  let(:response_base) do
    DummyBaseClass.new(OriginClass, response)
  end

  describe '#klass' do

    it 'returns the class' do
      expect(response.klass).to be(OriginClass)
    end
  end

  describe '#response' do

    it 'returns the response object' do
      expect(response_base.response).to eq(response)
    end
  end

  describe 'response document' do

    it 'returns the response document' do
      expect(response_base.response.response).to eq(response_document)
    end
  end

  describe '#total' do

    it 'returns the total' do
      expect(response_base.total).to eq(123)
    end
  end

  describe '#max_score' do

    it 'returns the total' do
      expect(response_base.max_score).to eq(456)
    end
  end

  describe '#results' do

    it 'raises a NotImplemented error' do
      expect {
        response_base.results
      }.to raise_exception(Elasticsearch::Model::NotImplemented)
    end
  end

  describe '#records' do

    it 'raises a NotImplemented error' do
      expect {
        response_base.records
      }.to raise_exception(Elasticsearch::Model::NotImplemented)
    end
  end
end
