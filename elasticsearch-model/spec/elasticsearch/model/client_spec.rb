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

describe Elasticsearch::Model::Client do

  before(:all) do
    class ::DummyClientModel
      extend  Elasticsearch::Model::Client::ClassMethods
      include Elasticsearch::Model::Client::InstanceMethods
    end
  end

  after(:all) do
    remove_classes(DummyClientModel)
  end

  context 'when a class includes the client module class methods' do

    it 'defines the client module class methods on the model' do
      expect(DummyClientModel.client).to be_a(Elasticsearch::Client)
    end
  end

  context 'when a class includes the client module instance methods' do

    it 'defines the client module class methods on the model' do
      expect(DummyClientModel.new.client).to be_a(Elasticsearch::Client)
    end
  end

  context 'when the client is set on the class' do

    around do |example|
      original_client = DummyClientModel.client
      DummyClientModel.client = 'foobar'
      example.run
      DummyClientModel.client = original_client
    end

    it 'sets the client on the class' do
      expect(DummyClientModel.client).to eq('foobar')
    end

    it 'sets the client on an instance' do
      expect(DummyClientModel.new.client).to eq('foobar')
    end
  end

  context 'when the client is set on an instance' do

    before do
      model_instance.client = 'foo'
    end

    let(:model_instance) do
      DummyClientModel.new
    end

    it 'sets the client on an instance' do
      expect(model_instance.client).to eq('foo')
    end

    it 'does not set the client on the class' do
      expect(DummyClientModel.client).to be_a(Elasticsearch::Client)
    end
  end
end
