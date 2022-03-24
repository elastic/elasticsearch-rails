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

describe OpenSearch::Model::Multimodel do

  let(:multimodel) do
    OpenSearch::Model::Multimodel.new(model_1, model_2)
  end

  let(:model_1) do
    double('Foo', index_name: 'foo_index', document_type: 'foo', to_ary: nil)
  end

  let(:model_2) do
    double('Bar', index_name: 'bar_index', document_type: 'bar', to_ary: nil)
  end

  it 'has an index name' do
    expect(multimodel.index_name).to eq(['foo_index', 'bar_index'])
  end

  it 'has an document type' do
    expect(multimodel.document_type).to eq(['foo', 'bar'])
  end

  it 'has a client' do
    expect(multimodel.client).to eq(OpenSearch::Model.client)
  end

  describe 'the model registry' do

    before(:all) do

      class JustAModel
        include OpenSearch::Model
      end

      class JustAnotherModel
        include OpenSearch::Model
      end
    end

    after(:all) do
      remove_classes(JustAModel, JustAnotherModel)
    end

    let(:multimodel) do
      OpenSearch::Model::Multimodel.new
    end

    it 'includes model in the registry' do
      expect(multimodel.models).to include(JustAModel)
      expect(multimodel.models).to include(JustAnotherModel)
    end
  end
end
