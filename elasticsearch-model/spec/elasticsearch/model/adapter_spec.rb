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

describe Elasticsearch::Model::Adapter do

  before(:all) do
    class ::DummyAdapterClass; end
    class ::DummyAdapterClassWithAdapter; end
    class ::DummyAdapter
      Records   = Module.new
      Callbacks = Module.new
      Importing = Module.new
    end
  end

  after(:all) do
    [DummyAdapterClassWithAdapter, DummyAdapterClass, DummyAdapter].each do |adapter|
      Elasticsearch::Model::Adapter::Adapter.adapters.delete(adapter)
    end
    remove_classes(DummyAdapterClass, DummyAdapterClassWithAdapter, DummyAdapter)
  end

  describe '#from_class' do

    it 'should return an Adapter instance' do
      expect(Elasticsearch::Model::Adapter.from_class(DummyAdapterClass)).to be_a(Elasticsearch::Model::Adapter::Adapter)
    end
  end

  describe 'register' do

    before do
      expect(Elasticsearch::Model::Adapter::Adapter).to receive(:register).and_call_original
      Elasticsearch::Model::Adapter.register(:foo, lambda { |c| false })
    end

    it 'should register an adapter' do
      expect(Elasticsearch::Model::Adapter::Adapter.adapters[:foo]).to be_a(Proc)
    end

    context 'when a specific adapter class is set' do

      before do
        expect(Elasticsearch::Model::Adapter::Adapter).to receive(:register).and_call_original
        Elasticsearch::Model::Adapter::Adapter.register(DummyAdapter,
                                                        lambda { |c| c == DummyAdapterClassWithAdapter })
      end

      let(:adapter) do
        Elasticsearch::Model::Adapter::Adapter.new(DummyAdapterClassWithAdapter)
      end

      it 'should register the adapter' do
        expect(adapter.adapter).to eq(DummyAdapter)
      end
    end
  end

  describe 'default adapter' do

    let(:adapter) do
      Elasticsearch::Model::Adapter::Adapter.new(DummyAdapterClass)
    end

    it 'sets a default adapter' do
      expect(adapter.adapter).to eq(Elasticsearch::Model::Adapter::Default)
    end
  end

  describe '#records_mixin' do

    before do
      Elasticsearch::Model::Adapter::Adapter.register(DummyAdapter,
                                                      lambda { |c| c == DummyAdapterClassWithAdapter })

    end

    let(:adapter) do
      Elasticsearch::Model::Adapter::Adapter.new(DummyAdapterClassWithAdapter)
    end

    it 'returns a Module' do
      expect(adapter.records_mixin).to be_a(Module)
    end
  end

  describe '#callbacks_mixin' do

    before do
      Elasticsearch::Model::Adapter::Adapter.register(DummyAdapter,
                                                      lambda { |c| c == DummyAdapterClassWithAdapter })

    end

    let(:adapter) do
      Elasticsearch::Model::Adapter::Adapter.new(DummyAdapterClassWithAdapter)
    end

    it 'returns a Module' do
      expect(adapter.callbacks_mixin).to be_a(Module)
    end
  end

  describe '#importing_mixin' do

    before do
      Elasticsearch::Model::Adapter::Adapter.register(DummyAdapter,
                                                      lambda { |c| c == DummyAdapterClassWithAdapter })

    end

    let(:adapter) do
      Elasticsearch::Model::Adapter::Adapter.new(DummyAdapterClassWithAdapter)
    end

    it 'returns a Module' do
      expect(adapter.importing_mixin).to be_a(Module)
    end
  end
end
