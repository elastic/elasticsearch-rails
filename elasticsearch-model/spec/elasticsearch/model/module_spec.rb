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

describe Elasticsearch::Model do

  describe '#client' do

    it 'should have a default' do
      expect(Elasticsearch::Model.client).to be_a(Elasticsearch::Transport::Client)
    end
  end

  describe '#client=' do

    before do
      Elasticsearch::Model.client = 'Foobar'
    end

    it 'should allow the client to be set' do
      expect(Elasticsearch::Model.client).to eq('Foobar')
    end
  end

  describe 'mixin' do

    before(:all) do
      class ::DummyIncludingModel; end
      class ::DummyIncludingModelWithSearchMethodDefined
        def self.search(query, options={})
          "SEARCH"
        end
      end

      DummyIncludingModel.__send__ :include, Elasticsearch::Model
      DummyIncludingModelWithSearchMethodDefined.__send__ :include, Elasticsearch::Model
    end

    after(:all) do
      remove_classes(DummyIncludingModel, DummyIncludingModelWithSearchMethodDefined)
    end

    it 'should include and set up the proxy' do
      expect(DummyIncludingModel).to respond_to(:__elasticsearch__)
      expect(DummyIncludingModel.new).to respond_to(:__elasticsearch__)
    end

    it 'should delegate methods to the proxy' do
      expect(DummyIncludingModel).to respond_to(:search)
      expect(DummyIncludingModel).to respond_to(:mapping)
      expect(DummyIncludingModel).to respond_to(:settings)
      expect(DummyIncludingModel).to respond_to(:index_name)
      expect(DummyIncludingModel).to respond_to(:document_type)
      expect(DummyIncludingModel).to respond_to(:import)
    end

    it 'should not interfere with existing methods' do
      expect(DummyIncludingModelWithSearchMethodDefined.search('foo')).to eq('SEARCH')
    end
  end

  describe '#settings' do

    it 'allows access to the settings' do
      expect(Elasticsearch::Model.settings).to eq({})
    end

    context 'when settings are changed' do

      before do
        Elasticsearch::Model.settings[:foo] = 'bar'
      end

      it 'persists the changes' do
        expect(Elasticsearch::Model.settings[:foo]).to eq('bar')
      end
    end
  end
end
