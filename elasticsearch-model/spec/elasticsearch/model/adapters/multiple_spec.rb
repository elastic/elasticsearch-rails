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

describe Elasticsearch::Model::Adapter::Multiple do

  before(:all) do
    class DummyOne
      include Elasticsearch::Model

      index_name 'dummy'
      document_type 'dummy_one'

      def self.find(ids)
        ids.map { |id| new(id) }
      end

      attr_reader :id

      def initialize(id)
        @id = id.to_i
      end
    end

    module Namespace
      class DummyTwo
        include Elasticsearch::Model

        index_name 'dummy'
        document_type 'dummy_two'

        def self.find(ids)
          ids.map { |id| new(id) }
        end

        attr_reader :id

        def initialize(id)
          @id = id.to_i
        end
      end
    end

    class DummyTwo
      include Elasticsearch::Model

      index_name 'other_index'
      document_type 'dummy_two'

      def self.find(ids)
        ids.map { |id| new(id) }
      end

      attr_reader :id

      def initialize(id)
        @id = id.to_i
      end
    end
  end

  after(:all) do
    [DummyOne, Namespace::DummyTwo, DummyTwo].each do |adapter|
      Elasticsearch::Model::Adapter::Adapter.adapters.delete(adapter)
    end
    Namespace.send(:remove_const, :DummyTwo) if defined?(Namespace::DummyTwo)
    remove_classes(DummyOne, DummyTwo, Namespace)
  end

  let(:hits) do
    [
      {
        _index: 'dummy',
        _type: 'dummy_two',
        _id: '2'
      },
      {
        _index: 'dummy',
        _type: 'dummy_one',
        _id: '2'
      },
      {
        _index: 'other_index',
        _type: 'dummy_two',
        _id: '1'
      },
      {
        _index: 'dummy',
        _type: 'dummy_two',
        _id: '1'
      },
      {
        _index: 'dummy',
        _type: 'dummy_one',
        _id: '3'
      }
    ]
  end

  let(:response) do
    double('response', response: { 'hits' => { 'hits' => hits } })
  end

  let(:multimodel) do
    Elasticsearch::Model::Multimodel.new(DummyOne, DummyTwo, Namespace::DummyTwo)
  end

  describe '#records' do

    before do
      multimodel.class.send :include, Elasticsearch::Model::Adapter::Multiple::Records
      expect(multimodel).to receive(:response).at_least(:once).and_return(response)
    end

    it 'instantiates the correct types of instances' do
      expect(multimodel.records[0]).to be_a(Namespace::DummyTwo)
      expect(multimodel.records[1]).to be_a(DummyOne)
      expect(multimodel.records[2]).to be_a(DummyTwo)
      expect(multimodel.records[3]).to be_a(Namespace::DummyTwo)
      expect(multimodel.records[4]).to be_a(DummyOne)
    end

    it 'returns the results in the correct order' do
      expect(multimodel.records.map(&:id)).to eq([2, 2, 1, 1, 3])
    end
  end
end
