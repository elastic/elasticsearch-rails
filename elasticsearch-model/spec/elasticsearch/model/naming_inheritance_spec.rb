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

describe 'naming inheritance' do

  before(:all) do
    class ::TestBase
      extend ActiveModel::Naming

      extend  Elasticsearch::Model::Naming::ClassMethods
      include Elasticsearch::Model::Naming::InstanceMethods
    end

    class ::Animal < ::TestBase
      extend ActiveModel::Naming

      extend  Elasticsearch::Model::Naming::ClassMethods
      include Elasticsearch::Model::Naming::InstanceMethods

      index_name "mammals"
      document_type "mammal"
    end

    class ::Dog < ::Animal
    end

    module ::MyNamespace
      class Dog < ::Animal
      end
    end

    class ::Cat < ::Animal
      extend ActiveModel::Naming

      extend  Elasticsearch::Model::Naming::ClassMethods
      include Elasticsearch::Model::Naming::InstanceMethods

      index_name "cats"
      document_type "cat"
    end

  end

  after(:all) do
    remove_classes(TestBase, Animal, MyNamespace, Cat)
  end

  around(:all) do |example|
    original_value = Elasticsearch::Model.settings[:inheritance_enabled]
    Elasticsearch::Model.settings[:inheritance_enabled] = true
    example.run
    Elasticsearch::Model.settings[:inheritance_enabled] = original_value
  end


  describe '#index_name' do

    it 'returns the default index name' do
      expect(TestBase.index_name).to eq('test_bases')
      expect(TestBase.new.index_name).to eq('test_bases')
    end

    it 'returns the explicit index name' do
      expect(Animal.index_name).to eq('mammals')
      expect(Animal.new.index_name).to eq('mammals')

      expect(Cat.index_name).to eq('cats')
      expect(Cat.new.index_name).to eq('cats')
    end

    it 'returns the ancestor index name' do
      expect(Dog.index_name).to eq('mammals')
      expect(Dog.new.index_name).to eq('mammals')
    end

    it 'returns the ancestor index name for namespaced models' do
      expect(::MyNamespace::Dog.index_name).to eq('mammals')
      expect(::MyNamespace::Dog.new.index_name).to eq('mammals')
    end
  end

  describe '#document_type' do

    it 'returns nil' do
      expect(TestBase.document_type).to be_nil
      expect(TestBase.new.document_type).to be_nil
    end

    it 'returns the explicit document type' do
      expect(Animal.document_type).to eq('mammal')
      expect(Animal.new.document_type).to eq('mammal')

      expect(Cat.document_type).to eq('cat')
      expect(Cat.new.document_type).to eq('cat')
    end

    it 'returns the ancestor document type' do
      expect(Dog.document_type).to eq('mammal')
      expect(Dog.new.document_type).to eq('mammal')
    end

    it 'returns the ancestor document type for namespaced models' do
      expect(::MyNamespace::Dog.document_type).to eq('mammal')
      expect(::MyNamespace::Dog.new.document_type).to eq('mammal')
    end
  end
end
