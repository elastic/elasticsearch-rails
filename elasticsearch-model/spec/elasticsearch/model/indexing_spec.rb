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

describe Elasticsearch::Model::Indexing do

  before(:all) do
    class ::DummyIndexingModel
      extend ActiveModel::Naming
      extend Elasticsearch::Model::Naming::ClassMethods
      extend Elasticsearch::Model::Indexing::ClassMethods

      def self.foo
        'bar'
      end
    end

    class NotFound < Exception; end
  end

  after(:all) do
    remove_classes(DummyIndexingModel, NotFound)
  end

  describe 'the Settings class' do

    it 'should be convertible to a hash' do
      expect(Elasticsearch::Model::Indexing::Settings.new(foo: 'bar').to_hash).to eq(foo: 'bar')
    end

    it 'should be convertible to json' do
      expect(Elasticsearch::Model::Indexing::Settings.new(foo: 'bar').as_json).to eq(foo: 'bar')
    end
  end

  describe '#settings' do

    it 'returns an instance of the Settings class' do
      expect(DummyIndexingModel.settings).to be_a(Elasticsearch::Model::Indexing::Settings)
    end

    context 'when the settings are updated' do

      before do
        DummyIndexingModel.settings(foo: 'boo')
        DummyIndexingModel.settings(bar: 'bam')
      end

      it 'updates the settings on the class' do
        expect(DummyIndexingModel.settings.to_hash).to eq(foo: 'boo', bar: 'bam')
      end
    end

    context 'when the settings are updated with a yml file' do

      before do
        DummyIndexingModel.settings File.open('spec/support/model.yml')
        DummyIndexingModel.settings bar: 'bam'
      end

      it 'updates the settings on the class' do
        expect(DummyIndexingModel.settings.to_hash).to eq(foo: 'boo', bar: 'bam', 'baz' => 'qux')
      end
    end

    context 'when the settings are updated with a json file' do

      before do
        DummyIndexingModel.settings File.open('spec/support/model.json')
        DummyIndexingModel.settings bar: 'bam'
      end

      it 'updates the settings on the class' do
        expect(DummyIndexingModel.settings.to_hash).to eq(foo: 'boo', bar: 'bam', 'baz' => 'qux', 'laz' => 'qux')
      end
    end
  end

  describe '#mappings' do

    let(:expected_mapping_hash) do
      { :mytype => { foo: 'bar', :properties => {} } }
    end

    it 'returns an instance of the Mappings class' do
      expect(DummyIndexingModel.mappings).to be_a(Elasticsearch::Model::Indexing::Mappings)
    end

    it 'does not raise an exception when there is no type passed to the #initialize method' do
      expect(Elasticsearch::Model::Indexing::Mappings.new)
    end

    it 'should be convertible to a hash' do
      expect(Elasticsearch::Model::Indexing::Mappings.new(:mytype, { foo: 'bar' }).to_hash).to eq(expected_mapping_hash)
    end

    it 'should be convertible to json' do
      expect(Elasticsearch::Model::Indexing::Mappings.new(:mytype, { foo: 'bar' }).as_json).to eq(expected_mapping_hash)
    end

    context 'when a type is specified' do

      let(:mappings) do
        Elasticsearch::Model::Indexing::Mappings.new(:mytype)
      end

      before do
        mappings.indexes :foo, { type: 'boolean', include_in_all: false }
        mappings.indexes :bar
      end

      it 'creates the correct mapping definition' do
        expect(mappings.to_hash[:mytype][:properties][:foo][:type]).to eq('boolean')
      end

      it 'uses text as the default field type' do
        expect(mappings.to_hash[:mytype][:properties][:bar][:type]).to eq('text')
      end

      context 'when the \'include_type_name\' option is specified' do

        let(:mappings) do
          Elasticsearch::Model::Indexing::Mappings.new(:mytype, include_type_name: true)
        end

        before do
          mappings.indexes :foo, { type: 'boolean', include_in_all: false }
        end

        it 'creates the correct mapping definition' do
          expect(mappings.to_hash[:mytype][:properties][:foo][:type]).to eq('boolean')
        end

        it 'sets the \'include_type_name\' option' do
          expect(mappings.to_hash[:mytype][:include_type_name]).to eq(true)
        end
      end
    end

    context 'when a type is not specified' do

      let(:mappings) do
        Elasticsearch::Model::Indexing::Mappings.new
      end

      before do
        mappings.indexes :foo, { type: 'boolean', include_in_all: false }
        mappings.indexes :bar
      end

      it 'creates the correct mapping definition' do
        expect(mappings.to_hash[:properties][:foo][:type]).to eq('boolean')
      end

      it 'uses text as the default type' do
        expect(mappings.to_hash[:properties][:bar][:type]).to eq('text')
      end
    end

    context 'when specific mappings are defined' do

      let(:mappings) do
        Elasticsearch::Model::Indexing::Mappings.new(:mytype, include_type_name: true)
      end

      before do
        mappings.indexes :foo, { type: 'boolean', include_in_all: false }
        mappings.indexes :bar
      end

      it 'creates the correct mapping definition' do
        expect(mappings.to_hash[:mytype][:properties][:foo][:type]).to eq('boolean')
      end

      it 'uses text as the default type' do
        expect(mappings.to_hash[:mytype][:properties][:bar][:type]).to eq('text')
      end

      context 'when mappings are defined for multiple fields' do

        before do
          mappings.indexes :my_field, type: 'text' do
            indexes :raw, type: 'keyword'
          end
        end

        it 'defines the mapping for all the fields' do
          expect(mappings.to_hash[:mytype][:properties][:my_field][:type]).to eq('text')
          expect(mappings.to_hash[:mytype][:properties][:my_field][:fields][:raw][:type]).to eq('keyword')
          expect(mappings.to_hash[:mytype][:properties][:my_field][:fields][:raw][:properties]).to be_nil
        end
      end

      context 'when embedded properties are defined' do

        before do
          mappings.indexes :foo do
            indexes :bar
          end

          mappings.indexes :foo_object, type: 'object' do
            indexes :bar
          end

          mappings.indexes :foo_nested, type: 'nested' do
            indexes :bar
          end

          mappings.indexes :foo_nested_as_symbol, type: :nested do
            indexes :bar
          end
        end

        it 'defines mappings for the embedded properties' do
          expect(mappings.to_hash[:mytype][:properties][:foo][:type]).to eq('object')
          expect(mappings.to_hash[:mytype][:properties][:foo][:properties][:bar][:type]).to eq('text')
          expect(mappings.to_hash[:mytype][:properties][:foo][:fields]).to be_nil

          expect(mappings.to_hash[:mytype][:properties][:foo_object][:type]).to eq('object')
          expect(mappings.to_hash[:mytype][:properties][:foo_object][:properties][:bar][:type]).to eq('text')
          expect(mappings.to_hash[:mytype][:properties][:foo_object][:fields]).to be_nil

          expect(mappings.to_hash[:mytype][:properties][:foo_nested][:type]).to eq('nested')
          expect(mappings.to_hash[:mytype][:properties][:foo_nested][:properties][:bar][:type]).to eq('text')
          expect(mappings.to_hash[:mytype][:properties][:foo_nested][:fields]).to be_nil

          expect(mappings.to_hash[:mytype][:properties][:foo_nested_as_symbol][:type]).to eq(:nested)
          expect(mappings.to_hash[:mytype][:properties][:foo_nested_as_symbol][:properties]).not_to be_nil
          expect(mappings.to_hash[:mytype][:properties][:foo_nested_as_symbol][:fields]).to be_nil
        end

        it 'defines the settings' do
          expect(mappings.to_hash[:mytype][:include_type_name]).to be(true)
        end
      end
    end

    context 'when the method is called on a class' do

      before do
        DummyIndexingModel.mappings(foo: 'boo')
        DummyIndexingModel.mappings(bar: 'bam')
      end

      let(:expected_mappings_hash) do
        { foo: "boo", bar: "bam", properties: {} }
      end

      it 'sets the mappings' do
        expect(DummyIndexingModel.mappings.to_hash).to eq(expected_mappings_hash)
      end

      context 'when the method is called with a block' do

        before do
          DummyIndexingModel.mapping do
            indexes :foo, type: 'boolean'
          end
        end

        it 'sets the mappings' do
          expect(DummyIndexingModel.mapping.to_hash[:properties][:foo][:type]).to eq('boolean')
        end
      end

      context 'when the class has a document_type' do

        before do
          DummyIndexingModel.instance_variable_set(:@mapping, nil)
          DummyIndexingModel.document_type(:mytype)
          DummyIndexingModel.mappings(foo: 'boo')
          DummyIndexingModel.mappings(bar: 'bam')
        end

        let(:expected_mappings_hash) do
          { mytype: { foo: "boo", bar: "bam", properties: {} } }
        end

        it 'sets the mappings' do
          expect(DummyIndexingModel.mappings.to_hash).to eq(expected_mappings_hash)
        end
      end
    end
  end

  describe 'instance methods' do

    before(:all) do
      class ::DummyIndexingModelWithCallbacks
        extend  Elasticsearch::Model::Indexing::ClassMethods
        include Elasticsearch::Model::Indexing::InstanceMethods

        def self.before_save(&block)
          (@callbacks ||= {})[block.hash] = block
        end

        def changes_to_save
          {:foo => ['One', 'Two']}
        end
      end

      class ::DummyIndexingModelWithNoChanges
        extend  Elasticsearch::Model::Indexing::ClassMethods
        include Elasticsearch::Model::Indexing::InstanceMethods

        def self.before_save(&block)
          (@callbacks ||= {})[block.hash] = block
        end

        def changes_to_save
          {}
        end
      end

      class ::DummyIndexingModelWithCallbacksAndCustomAsIndexedJson
        extend  Elasticsearch::Model::Indexing::ClassMethods
        include Elasticsearch::Model::Indexing::InstanceMethods

        def self.before_save(&block)
          (@callbacks ||= {})[block.hash] = block
        end

        def changes_to_save
          {:foo => ['A', 'B'], :bar => ['C', 'D']}
        end

        def as_indexed_json(options={})
          { :foo => 'B' }
        end
      end

      class ::DummyIndexingModelWithOldDirty
        extend  Elasticsearch::Model::Indexing::ClassMethods
        include Elasticsearch::Model::Indexing::InstanceMethods

        def self.before_save(&block)
          (@callbacks ||= {})[block.hash] = block
        end

        def changes
          {:foo => ['One', 'Two']}
        end
      end
    end

    after(:all) do
      Object.send(:remove_const, :DummyIndexingModelWithCallbacks) if defined?(DummyIndexingModelWithCallbacks)
      Object.send(:remove_const, :DummyIndexingModelWithNoChanges) if defined?(DummyIndexingModelWithNoChanges)
      Object.send(:remove_const, :DummyIndexingModelWithCallbacksAndCustomAsIndexedJson) if defined?(DummyIndexingModelWithCallbacksAndCustomAsIndexedJson)
      Object.send(:remove_const, :DummyIndexingModelWithOldDirty) if defined?(DummyIndexingModelWithOldDirty)
    end

    context 'when the module is included' do

      context 'when the model uses the old ActiveModel::Dirty' do

        before do
          DummyIndexingModelWithOldDirty.__send__ :include, Elasticsearch::Model::Indexing::InstanceMethods
        end

        it 'registers callbacks' do
          expect(DummyIndexingModelWithOldDirty.instance_variable_get(:@callbacks)).not_to be_empty
        end

        let(:instance) do
          DummyIndexingModelWithOldDirty.new
        end

        it 'sets the @__changed_model_attributes variable before the callback' do
          DummyIndexingModelWithOldDirty.instance_variable_get(:@callbacks).each do |n, callback|
            instance.instance_eval(&callback)
            expect(instance.instance_variable_get(:@__changed_model_attributes)).to eq(foo: 'Two')
          end
        end
      end

      context 'when the model users the current ActiveModel::Dirty' do

        before do
          DummyIndexingModelWithCallbacks.__send__ :include, Elasticsearch::Model::Indexing::InstanceMethods
        end

        it 'registers callbacks' do
          expect(DummyIndexingModelWithCallbacks.instance_variable_get(:@callbacks)).not_to be_empty
        end

        let(:instance) do
          DummyIndexingModelWithCallbacks.new
        end

        it 'sets the @__changed_model_attributes variable before the callback' do
          DummyIndexingModelWithCallbacks.instance_variable_get(:@callbacks).each do |n, callback|
            instance.instance_eval(&callback)
            expect(instance.instance_variable_get(:@__changed_model_attributes)).to eq(foo: 'Two')
          end
        end
      end
    end

    describe '#index_document' do

      before do
        expect(instance).to receive(:client).and_return(client)
        expect(instance).to receive(:as_indexed_json).and_return('JSON')
        expect(instance).to receive(:index_name).and_return('foo')
        expect(instance).to receive(:document_type).twice.and_return('bar')
        expect(instance).to receive(:id).and_return('1')
      end

      let(:client) do
        double('client')
      end

      let(:instance) do
        DummyIndexingModelWithCallbacks.new
      end

      context 'when no options are passed to the method' do

        before do
          expect(client).to receive(:index).with(index: 'foo', type: 'bar', id: '1', body: 'JSON').and_return(true)
        end

        it 'provides the method on an instance' do
          expect(instance.index_document).to be(true)
        end
      end

      context 'when extra options are passed to the method' do

        before do
          expect(client).to receive(:index).with(index: 'foo', type: 'bar', id: '1', body: 'JSON', parent: 'A').and_return(true)
        end

        it 'passes the extra options to the method call on the client' do
          expect(instance.index_document(parent: 'A')).to be(true)
        end
      end
    end

    describe '#delete_document' do

      before do
        expect(instance).to receive(:client).and_return(client)
        expect(instance).to receive(:index_name).and_return('foo')
        expect(instance).to receive(:document_type).twice.and_return('bar')
        expect(instance).to receive(:id).and_return('1')
      end

      let(:client) do
        double('client')
      end

      let(:instance) do
        DummyIndexingModelWithCallbacks.new
      end

      context 'when no options are passed to the method' do

        before do
          expect(client).to receive(:delete).with(index: 'foo', type: 'bar', id: '1').and_return(true)
        end

        it 'provides the method on an instance' do
          expect(instance.delete_document).to be(true)
        end
      end

      context 'when extra options are passed to the method' do

        before do
          expect(client).to receive(:delete).with(index: 'foo', type: 'bar', id: '1', parent: 'A').and_return(true)
        end

        it 'passes the extra options to the method call on the client' do
          expect(instance.delete_document(parent: 'A')).to be(true)
        end
      end
    end

    describe '#update_document' do

      let(:client) do
        double('client')
      end

      let(:instance) do
        DummyIndexingModelWithCallbacks.new
      end

      context 'when no changes are present' do

        before do
          expect(instance).to receive(:index_document).and_return(true)
          expect(client).to receive(:update).never
          instance.instance_variable_set(:@__changed_model_attributes, nil)
        end

        it 'updates the document' do
          expect(instance.update_document).to be(true)
        end
      end

      context 'when changes are present' do

        before do
          allow(instance).to receive(:client).and_return(client)
          allow(instance).to receive(:index_name).and_return('foo')
          allow(instance).to receive(:document_type).and_return('bar')
          allow(instance).to receive(:id).and_return('1')
        end

        context 'when the changes are included in the as_indexed_json representation' do

          before do
            instance.instance_variable_set(:@__changed_model_attributes, { foo: 'bar' })
            expect(client).to receive(:update).with(index: 'foo', type: 'bar', id: '1', body: { doc: { foo: 'bar' } }).and_return(true)
          end

          it 'updates the document' do
            expect(instance.update_document).to be(true)
          end
        end

        context 'when the changes are not all included in the as_indexed_json representation' do

          let(:instance) do
            DummyIndexingModelWithCallbacksAndCustomAsIndexedJson.new
          end

          before do
            instance.instance_variable_set(:@__changed_model_attributes, {'foo' => 'B', 'bar' => 'D' })
            expect(client).to receive(:update).with(index: 'foo', type: 'bar', id: '1', body: { doc: { foo: 'B' } }).and_return(true)
          end

          it 'updates the document' do
            expect(instance.update_document).to be(true)
          end
        end

        context 'when none of the changes are included in the as_indexed_json representation' do

          let(:instance) do
            DummyIndexingModelWithCallbacksAndCustomAsIndexedJson.new
          end

          before do
            instance.instance_variable_set(:@__changed_model_attributes, {'bar' => 'D' })
          end

          it 'does not update the document' do
            expect(instance.update_document).to_not be(true)
          end
        end

        context 'when there are partial updates' do

          let(:instance) do
            DummyIndexingModelWithCallbacksAndCustomAsIndexedJson.new
          end

          before do
            instance.instance_variable_set(:@__changed_model_attributes, { 'foo' => { 'bar' => 'BAR'} })
            expect(instance).to receive(:as_indexed_json).and_return('foo' => 'BAR')
            expect(client).to receive(:update).with(index: 'foo', type: 'bar', id: '1', body: { doc: { 'foo' => 'BAR' } }).and_return(true)
          end

          it 'updates the document' do
            expect(instance.update_document).to be(true)
          end
        end
      end
    end

    describe '#update_document_attributes' do

      let(:client) do
        double('client')
      end

      let(:instance) do
        DummyIndexingModelWithCallbacks.new
      end

      context 'when changes are present' do

        before do
          expect(instance).to receive(:client).and_return(client)
          expect(instance).to receive(:index_name).and_return('foo')
          expect(instance).to receive(:document_type).twice.and_return('bar')
          expect(instance).to receive(:id).and_return('1')
          instance.instance_variable_set(:@__changed_model_attributes, { author: 'john' })
        end

        context 'when no options are specified' do

          before do
            expect(client).to receive(:update).with(index: 'foo', type: 'bar', id: '1', body: { doc: { title: 'green' } }).and_return(true)
          end

          it 'updates the document' do
            expect(instance.update_document_attributes(title: 'green')).to be(true)
          end
        end

        context 'when extra options are provided' do

          before do
            expect(client).to receive(:update).with(index: 'foo', type: 'bar', id: '1', body: { doc: { title: 'green' } }, refresh: true).and_return(true)
          end

          it 'updates the document' do
            expect(instance.update_document_attributes({ title: 'green' }, refresh: true)).to be(true)
          end
        end
      end
    end
  end

  describe '#index_exists?' do

    before do
      expect(DummyIndexingModel).to receive(:client).and_return(client)
    end

    context 'when the index exists' do

      let(:client) do
        double('client', indices: double('indices', exists: true))
      end

      it 'returns true' do
        expect(DummyIndexingModel.index_exists?).to be(true)
      end
    end

    context 'when the index does not exists' do

      let(:client) do
        double('client', indices: double('indices', exists: false))
      end

      it 'returns false' do
        expect(DummyIndexingModel.index_exists?).to be(false)
      end
    end
  end

  describe '#delete_index!' do

    before(:all) do
      class ::DummyIndexingModelForRecreate
        extend ActiveModel::Naming
        extend Elasticsearch::Model::Naming::ClassMethods
        extend Elasticsearch::Model::Indexing::ClassMethods
      end
    end

    after(:all) do
      Object.send(:remove_const, :DummyIndexingModelForRecreate) if defined?(DummyIndexingModelForRecreate)
    end

    context 'when the index is not found' do
      let(:client) do
        double(
          'client',
          indices: indices,
          transport: double(
            'transport',
            double('transport', { logger: nil })
          )
        )
      end

      let(:indices) do
        double('indices').tap do |ind|
          expect(ind).to receive(:delete).and_raise(NotFound)
        end
      end

      before do
        expect(DummyIndexingModelForRecreate).to receive(:client).at_most(3).times.and_return(client)
      end

      context 'when the force option is true' do

        it 'deletes the index without raising an exception' do
          expect(DummyIndexingModelForRecreate.delete_index!(force: true)).to be_nil
        end

        context 'when the client has a logger' do

          let(:logger) do
            Logger.new(STDOUT).tap { |l| l.level = Logger::DEBUG }
          end

          let(:client) do
            double('client', indices: indices, transport: double('transport', { logger: logger }))
          end

          it 'deletes the index without raising an exception' do
            expect(DummyIndexingModelForRecreate.delete_index!(force: true)).to be_nil
          end

          it 'logs the message that the index is not found' do
            expect(logger).to receive(:debug)
            expect(DummyIndexingModelForRecreate.delete_index!(force: true)).to be_nil
          end
        end
      end

      context 'when the force option is not provided' do

        it 'raises an exception' do
          expect {
            DummyIndexingModelForRecreate.delete_index!
          }.to raise_exception(NotFound)
        end
      end

      context 'when the exception is not NotFound' do

        let(:indices) do
          double('indices').tap do |ind|
            expect(ind).to receive(:delete).and_raise(Exception)
          end
        end

        it 'raises an exception' do
          expect {
            DummyIndexingModelForRecreate.delete_index!
          }.to raise_exception(Exception)
        end
      end
    end

    context 'when an index name is provided in the options' do

      before do
        expect(DummyIndexingModelForRecreate).to receive(:client).and_return(client)
        expect(indices).to receive(:delete).with(index: 'custom-foo')
      end

      let(:client) do
        double('client', indices: indices)
      end

      let(:indices) do
        double('indices', delete: true)
      end

      it 'uses the index name' do
        expect(DummyIndexingModelForRecreate.delete_index!(index: 'custom-foo'))
      end
    end
  end

  describe '#create_index' do

    before(:all) do
      class ::DummyIndexingModelForCreate
        extend ActiveModel::Naming
        extend Elasticsearch::Model::Naming::ClassMethods
        extend Elasticsearch::Model::Indexing::ClassMethods

        index_name 'foo'

        settings index: { number_of_shards: 1 } do
          mappings do
            indexes :foo, analyzer: 'keyword'
          end
        end
      end
    end

    after(:all) do
      Object.send(:remove_const, :DummyIndexingModelForCreate) if defined?(DummyIndexingModelForCreate)
    end

    let(:client) do
      double('client', indices: indices)
    end

    let(:indices) do
      double('indices')
    end

    context 'when the index does not exist' do

      before do
        expect(DummyIndexingModelForCreate).to receive(:client).and_return(client)
        expect(DummyIndexingModelForCreate).to receive(:index_exists?).and_return(false)
      end

      context 'when options are not provided' do

        let(:expected_body) do
          { mappings: { properties: { foo: { analyzer: 'keyword',
                                                     type: 'text' } } },
            settings: { index: { number_of_shards: 1 } } }
        end

        before do
          expect(indices).to receive(:create).with(index: 'foo', body: expected_body).and_return(true)
        end

        it 'creates the index' do
          expect(DummyIndexingModelForCreate.create_index!).to be(true)
        end
      end

      context 'when options are provided' do

        let(:expected_body) do
          { mappings: { foobar: { properties: { foo: { analyzer: 'bar' } } } },
            settings: { index: { number_of_shards: 3 } } }
        end

        before do
          expect(indices).to receive(:create).with(index: 'foobar', body: expected_body).and_return(true)
        end

        it 'creates the index' do
          expect(DummyIndexingModelForCreate.create_index! \
            index: 'foobar',
            settings: { index: { number_of_shards: 3 } },
            mappings: { foobar: { properties: { foo: { analyzer: 'bar' } } } }
          ).to be(true)
        end
      end
    end

    context 'when the index exists' do

      before do
        expect(DummyIndexingModelForCreate).to receive(:index_exists?).and_return(true)
        expect(indices).to receive(:create).never
      end

      it 'does not create the index' do
        expect(DummyIndexingModelForCreate.create_index!).to be_nil
      end
    end

    context 'when creating the index raises an exception' do

      before do
        expect(DummyIndexingModelForCreate).to receive(:client).and_return(client)
        expect(DummyIndexingModelForCreate).to receive(:delete_index!).and_return(true)
        expect(DummyIndexingModelForCreate).to receive(:index_exists?).and_return(false)
        expect(indices).to receive(:create).and_raise(Exception)
      end

      it 'raises the exception' do
        expect {
          DummyIndexingModelForCreate.create_index!(force: true)
        }.to raise_exception(Exception)
      end
    end

    context 'when an index name is provided in the options' do

      before do
        expect(DummyIndexingModelForCreate).to receive(:client).and_return(client).twice
        expect(indices).to receive(:exists).and_return(false)
        expect(indices).to receive(:create).with(index: 'custom-foo', body: expected_body)
      end

      let(:expected_body) do
        { mappings: { properties: { foo: { analyzer: 'keyword',
                                                   type: 'text' } } },
          settings: { index: { number_of_shards: 1 } } }
      end

      it 'uses the index name' do
        expect(DummyIndexingModelForCreate.create_index!(index: 'custom-foo'))
      end
    end

    context 'when the logging level is debug'
  end

  describe '#refresh_index!' do

    before(:all) do
      class ::DummyIndexingModelForRefresh
        extend ActiveModel::Naming
        extend Elasticsearch::Model::Naming::ClassMethods
        extend Elasticsearch::Model::Indexing::ClassMethods

        index_name 'foo'

        settings index: { number_of_shards: 1 } do
          mappings do
            indexes :foo, analyzer: 'keyword'
          end
        end
      end
    end

    after(:all) do
      Object.send(:remove_const, :DummyIndexingModelForRefresh) if defined?(DummyIndexingModelForRefresh)
    end

    let(:client) do
      double('client', indices: indices, transport: double('transport', { logger: nil }))
    end

    let(:indices) do
      double('indices')
    end

    before do
      expect(DummyIndexingModelForRefresh).to receive(:client).at_most(3).times.and_return(client)
    end

    context 'when the force option is true' do

      context 'when the operation raises a NotFound exception' do

        before do
          expect(indices).to receive(:refresh).and_raise(NotFound)
        end

        it 'does not raise an exception' do
          expect(DummyIndexingModelForRefresh.refresh_index!(force: true)).to be_nil
        end

        context 'when the client has a logger' do

          let(:logger) do
            Logger.new(STDOUT).tap { |l| l.level = Logger::DEBUG }
          end

          let(:client) do
            double('client', indices: indices, transport: double('transport', { logger: logger }))
          end

          it 'does not raise an exception' do
            expect(DummyIndexingModelForRefresh.refresh_index!(force: true)).to be_nil
          end

          it 'logs the message that the index is not found' do
            expect(logger).to receive(:debug)
            expect(DummyIndexingModelForRefresh.refresh_index!(force: true)).to be_nil
          end
        end
      end

      context 'when the operation raises another type of exception' do

        before do
          expect(indices).to receive(:refresh).and_raise(Exception)
        end

        it 'does not raise an exception' do
          expect {
            DummyIndexingModelForRefresh.refresh_index!(force: true)
          }.to raise_exception(Exception)
        end
      end
    end

    context 'when an index name is provided in the options' do

      before do
        expect(indices).to receive(:refresh).with(index: 'custom-foo')
      end

      it 'uses the index name' do
        expect(DummyIndexingModelForRefresh.refresh_index!(index: 'custom-foo'))
      end
    end
  end
end
