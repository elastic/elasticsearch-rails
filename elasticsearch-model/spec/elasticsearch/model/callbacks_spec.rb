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

describe Elasticsearch::Model::Callbacks do

  before(:all) do
    class ::DummyCallbacksModel
    end

    module DummyCallbacksAdapter
      module CallbacksMixin
      end

      def callbacks_mixin
        CallbacksMixin
      end; module_function :callbacks_mixin
    end
  end

  after(:all) do
    remove_classes(DummyCallbacksModel, DummyCallbacksAdapter)
  end

  context 'when a model includes the Callbacks module' do

    before do
      Elasticsearch::Model::Callbacks.included(DummyCallbacksModel)
    end

    it 'includes the callbacks mixin from the model adapter' do
      expect(DummyCallbacksModel.ancestors).to include(Elasticsearch::Model::Adapter::Default::Callbacks)
    end
  end
end
