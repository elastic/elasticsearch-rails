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

describe Elasticsearch::Model::Adapter::Default do

  before(:all) do
    class DummyClassForDefaultAdapter; end
    DummyClassForDefaultAdapter.__send__ :include, Elasticsearch::Model::Adapter::Default::Records
    DummyClassForDefaultAdapter.__send__ :include, Elasticsearch::Model::Adapter::Default::Importing
  end

  after(:all) do
    Elasticsearch::Model::Adapter::Adapter.adapters.delete(DummyClassForDefaultAdapter)
    remove_classes(DummyClassForDefaultAdapter)
  end

  let(:instance) do
    DummyClassForDefaultAdapter.new.tap do |m|
      allow(m).to receive(:klass).and_return(double('class', primary_key: :some_key, find: [1])).at_least(:once)
    end
  end

  it 'should have the default records implementation' do
    expect(instance.records).to eq([1])
  end

  it 'should have the default Callback implementation' do
    expect(Elasticsearch::Model::Adapter::Default::Callbacks).to be_a(Module)
  end

  it 'should have the default Importing implementation' do
    expect {
      DummyClassForDefaultAdapter.new.__find_in_batches
    }.to raise_exception(Elasticsearch::Model::NotImplemented)
  end

  it 'should have the default transform implementation' do
    expect {
      DummyClassForDefaultAdapter.new.__transform
    }.to raise_exception(Elasticsearch::Model::NotImplemented)
  end
end
