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

describe 'naming' do

  before(:all) do
    class ::DummyNamingModel
      extend ActiveModel::Naming

      extend  Elasticsearch::Model::Naming::ClassMethods
      include Elasticsearch::Model::Naming::InstanceMethods
    end

    module ::MyNamespace
      class DummyNamingModelInNamespace
        extend ActiveModel::Naming

        extend  Elasticsearch::Model::Naming::ClassMethods
        include Elasticsearch::Model::Naming::InstanceMethods
      end
    end
  end

  after(:all) do
    remove_classes(DummyNamingModel, MyNamespace)
  end

  it 'returns the default index name' do
    expect(DummyNamingModel.index_name).to eq('dummy_naming_models')
    expect(DummyNamingModel.new.index_name).to eq('dummy_naming_models')
  end

  it 'returns the sanitized defualt index name for namespaced models' do
    expect(::MyNamespace::DummyNamingModelInNamespace.index_name).to eq('my_namespace-dummy_naming_model_in_namespaces')
    expect(::MyNamespace::DummyNamingModelInNamespace.new.index_name).to eq('my_namespace-dummy_naming_model_in_namespaces')
  end

  describe '#index_name' do

    context 'when the index name is set on the class' do

      before do
        DummyNamingModel.index_name 'foobar'
      end

      it 'sets the index_name' do
        expect(DummyNamingModel.index_name).to eq('foobar')
      end
    end

    context 'when the index name is set on an instance' do

      before do
        instance.index_name 'foobar_d'
      end

      let(:instance) do
        DummyNamingModel.new
      end

      it 'sets the index name on the instance' do
        expect(instance.index_name).to eq('foobar_d')
      end

      context 'when the index name is set with a proc' do

        before do
          modifier = 'r'
          instance.index_name Proc.new{ "foobar_#{modifier}" }
        end

        it 'sets the index name on the instance' do
          expect(instance.index_name).to eq('foobar_r')
        end
      end
    end
  end

  describe '#index_name=' do

    before do
      DummyNamingModel.index_name = 'foobar_index_S'
    end

    it 'changes the index name' do
      expect(DummyNamingModel.index_name).to eq('foobar_index_S')
    end

    context 'when the method is called on an instance' do

      let(:instance) do
        DummyNamingModel.new
      end

      before do
        instance.index_name = 'foobar_index_s'
      end

      it 'changes the index name' do
        expect(instance.index_name).to eq('foobar_index_s')
      end

      it 'does not change the index name on the class' do
        expect(DummyNamingModel.index_name).to eq('foobar_index_S')
      end
    end

    context 'when the index name is changed with a proc' do

      before do
        modifier2 = 'y'
        DummyNamingModel.index_name = Proc.new{ "foobar_index_#{modifier2}" }
      end

      it 'changes the index name' do
        expect(DummyNamingModel.index_name).to eq('foobar_index_y')
      end
    end
  end
end
