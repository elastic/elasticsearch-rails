require 'test_helper'

class Elasticsearch::Model::IndexingTest < Test::Unit::TestCase
  context "Indexing module: " do
    class ::DummyIndexingModel
      extend ActiveModel::Naming
      extend Elasticsearch::Model::Naming::ClassMethods
      extend Elasticsearch::Model::Indexing::ClassMethods

      def self.foo
        'bar'
      end
    end

    class NotFound < Exception; end

    context "Settings class" do
      should "be convertible to hash" do
        hash     = { foo: 'bar' }
        settings = Elasticsearch::Model::Indexing::Settings.new hash
        assert_equal hash, settings.to_hash
        assert_equal settings.to_hash, settings.as_json
      end
    end

    context "Settings method" do
      should "initialize the index settings" do
        assert_instance_of Elasticsearch::Model::Indexing::Settings, DummyIndexingModel.settings
      end

      should "update and return the index settings from a hash" do
        DummyIndexingModel.settings foo: 'boo'
        DummyIndexingModel.settings bar: 'bam'

        assert_equal( {foo: 'boo', bar: 'bam'},  DummyIndexingModel.settings.to_hash)
      end

      should "update and return the index settings from a yml file" do
        DummyIndexingModel.settings File.open("test/support/model.yml")
        DummyIndexingModel.settings bar: 'bam'

        assert_equal( {foo: 'boo', bar: 'bam', 'baz' => 'qux'}, DummyIndexingModel.settings.to_hash)
      end

      should "update and return the index settings from a json file" do
        DummyIndexingModel.settings File.open("test/support/model.json")
        DummyIndexingModel.settings bar: 'bam'

        assert_equal( {foo: 'boo', bar: 'bam', 'baz' => 'qux'}, DummyIndexingModel.settings.to_hash)
      end

      should "evaluate the block" do
        DummyIndexingModel.expects(:foo)

        DummyIndexingModel.settings do
          foo
        end
      end
    end

    context "Mappings class" do
      should "initialize the index mappings" do
        assert_instance_of Elasticsearch::Model::Indexing::Mappings, DummyIndexingModel.mappings
      end

      should "raise an exception when not passed type" do
        assert_raise ArgumentError do
          Elasticsearch::Model::Indexing::Mappings.new
        end
      end

      should "be convertible to hash" do
        mappings = Elasticsearch::Model::Indexing::Mappings.new :mytype, { foo: 'bar' }
        assert_equal( { :mytype => { foo: 'bar', :properties => {} } }, mappings.to_hash )
        assert_equal mappings.to_hash, mappings.as_json
      end

      should "define properties" do
        mappings = Elasticsearch::Model::Indexing::Mappings.new :mytype
        assert_respond_to mappings, :indexes

        mappings.indexes :foo, { type: 'boolean', include_in_all: false }
        assert_equal 'boolean', mappings.to_hash[:mytype][:properties][:foo][:type]
      end

      should "define type as string by default" do
        mappings = Elasticsearch::Model::Indexing::Mappings.new :mytype

        mappings.indexes :bar, {}
        assert_equal 'string', mappings.to_hash[:mytype][:properties][:bar][:type]
      end

      should "define multiple fields" do
        mappings = Elasticsearch::Model::Indexing::Mappings.new :mytype

        mappings.indexes :foo_1, type: 'string' do
          indexes :raw, analyzer: 'keyword'
        end

        mappings.indexes :foo_2, type: 'multi_field' do
          indexes :raw, analyzer: 'keyword'
        end

        assert_equal 'string',  mappings.to_hash[:mytype][:properties][:foo_1][:type]
        assert_equal 'string',  mappings.to_hash[:mytype][:properties][:foo_1][:fields][:raw][:type]
        assert_equal 'keyword', mappings.to_hash[:mytype][:properties][:foo_1][:fields][:raw][:analyzer]
        assert_nil              mappings.to_hash[:mytype][:properties][:foo_1][:properties]

        assert_equal 'multi_field',  mappings.to_hash[:mytype][:properties][:foo_2][:type]
        assert_equal 'string',  mappings.to_hash[:mytype][:properties][:foo_2][:fields][:raw][:type]
        assert_equal 'keyword', mappings.to_hash[:mytype][:properties][:foo_2][:fields][:raw][:analyzer]
        assert_nil              mappings.to_hash[:mytype][:properties][:foo_2][:properties]
      end

      should "define embedded properties" do
        mappings = Elasticsearch::Model::Indexing::Mappings.new :mytype

        mappings.indexes :foo do
          indexes :bar
        end

        mappings.indexes :foo_object, type: 'object' do
          indexes :bar
        end

        mappings.indexes :foo_nested, type: 'nested' do
          indexes :bar
        end

        # Object is the default when `type` is missing and there's a block passed
        #
        assert_equal 'object', mappings.to_hash[:mytype][:properties][:foo][:type]
        assert_equal 'string', mappings.to_hash[:mytype][:properties][:foo][:properties][:bar][:type]
        assert_nil             mappings.to_hash[:mytype][:properties][:foo][:fields]

        assert_equal 'object', mappings.to_hash[:mytype][:properties][:foo_object][:type]
        assert_equal 'string', mappings.to_hash[:mytype][:properties][:foo_object][:properties][:bar][:type]
        assert_nil             mappings.to_hash[:mytype][:properties][:foo_object][:fields]

        assert_equal 'nested', mappings.to_hash[:mytype][:properties][:foo_nested][:type]
        assert_equal 'string', mappings.to_hash[:mytype][:properties][:foo_nested][:properties][:bar][:type]
        assert_nil             mappings.to_hash[:mytype][:properties][:foo_nested][:fields]
      end
    end

    context "Mappings method" do
      should "initialize the index mappings" do
        assert_instance_of Elasticsearch::Model::Indexing::Mappings, DummyIndexingModel.mappings
      end

      should "update and return the index mappings" do
        DummyIndexingModel.mappings foo: 'boo'
        DummyIndexingModel.mappings bar: 'bam'
        assert_equal( { dummy_indexing_model: { foo: "boo", bar: "bam", properties: {} } },
                      DummyIndexingModel.mappings.to_hash )
      end

      should "evaluate the block" do
        DummyIndexingModel.mappings.expects(:indexes).with(:foo).returns(true)

        DummyIndexingModel.mappings do
          indexes :foo
        end
      end
    end

    context "Instance methods" do
      class ::DummyIndexingModelWithCallbacks
        extend  Elasticsearch::Model::Indexing::ClassMethods
        include Elasticsearch::Model::Indexing::InstanceMethods

        def self.before_save(&block)
          (@callbacks ||= {})[block.hash] = block
        end

        def changed_attributes; [:foo]; end

        def changes
          {:foo => ['One', 'Two']}
        end
      end

      class ::DummyIndexingModelWithCallbacksAndCustomAsIndexedJson
        extend  Elasticsearch::Model::Indexing::ClassMethods
        include Elasticsearch::Model::Indexing::InstanceMethods

        def self.before_save(&block)
          (@callbacks ||= {})[block.hash] = block
        end

        def changed_attributes; [:foo, :bar]; end

        def changes
          {:foo => ['A', 'B'], :bar => ['C', 'D']}
        end

        def as_indexed_json(options={})
          { :foo => 'B' }
        end
      end

      should "register before_save callback when included" do
        ::DummyIndexingModelWithCallbacks.expects(:before_save).returns(true)
        ::DummyIndexingModelWithCallbacks.__send__ :include, Elasticsearch::Model::Indexing::InstanceMethods
      end

      should "set the @__changed_attributes variable before save" do
        instance = ::DummyIndexingModelWithCallbacks.new
        instance.expects(:instance_variable_set).with do |name, value|
          assert_equal :@__changed_attributes, name
          assert_equal({foo: 'Two'}, value)
          true
        end

        ::DummyIndexingModelWithCallbacks.__send__ :include, Elasticsearch::Model::Indexing::InstanceMethods

        ::DummyIndexingModelWithCallbacks.instance_variable_get(:@callbacks).each do |n,b|
          instance.instance_eval(&b)
        end
      end

      should "have the index_document method" do
        client   = mock('client')
        instance = ::DummyIndexingModelWithCallbacks.new

        client.expects(:index).with do |payload|
          assert_equal 'foo',  payload[:index]
          assert_equal 'bar',  payload[:type]
          assert_equal '1',    payload[:id]
          assert_equal 'JSON', payload[:body]
          true
        end

        instance.expects(:client).returns(client)
        instance.expects(:as_indexed_json).returns('JSON')
        instance.expects(:index_name).returns('foo')
        instance.expects(:document_type).returns('bar')
        instance.expects(:id).returns('1')

        instance.index_document
      end

      should "pass extra options to the index_document method to client.index" do
        client   = mock('client')
        instance = ::DummyIndexingModelWithCallbacks.new

        client.expects(:index).with do |payload|
          assert_equal 'A',  payload[:parent]
          true
        end

        instance.expects(:client).returns(client)
        instance.expects(:as_indexed_json).returns('JSON')
        instance.expects(:index_name).returns('foo')
        instance.expects(:document_type).returns('bar')
        instance.expects(:id).returns('1')

        instance.index_document(parent: 'A')
      end

      should "have the delete_document method" do
        client   = mock('client')
        instance = ::DummyIndexingModelWithCallbacks.new

        client.expects(:delete).with do |payload|
          assert_equal 'foo',  payload[:index]
          assert_equal 'bar',  payload[:type]
          assert_equal '1',    payload[:id]
          true
        end

        instance.expects(:client).returns(client)
        instance.expects(:index_name).returns('foo')
        instance.expects(:document_type).returns('bar')
        instance.expects(:id).returns('1')

        instance.delete_document()
      end

      should "pass extra options to the delete_document method to client.delete" do
        client   = mock('client')
        instance = ::DummyIndexingModelWithCallbacks.new

        client.expects(:delete).with do |payload|
          assert_equal 'A',  payload[:parent]
          true
        end

        instance.expects(:client).returns(client)
        instance.expects(:id).returns('1')
        instance.expects(:index_name).returns('foo')
        instance.expects(:document_type).returns('bar')

        instance.delete_document(parent: 'A')
      end

      should "update the document by re-indexing when no changes are present" do
        client   = mock('client')
        instance = ::DummyIndexingModelWithCallbacks.new

        # Reset the fake `changes`
        instance.instance_variable_set(:@__changed_attributes, nil)

        instance.expects(:index_document)
        instance.update_document
      end

      should "update the document by partial update when changes are present" do
        client   = mock('client')
        instance = ::DummyIndexingModelWithCallbacks.new

        # Set the fake `changes` hash
        instance.instance_variable_set(:@__changed_attributes, {foo: 'bar'})

        client.expects(:update).with do |payload|
          assert_equal 'foo',  payload[:index]
          assert_equal 'bar',  payload[:type]
          assert_equal '1',    payload[:id]
          assert_equal({foo: 'bar'}, payload[:body][:doc])
          true
        end

        instance.expects(:client).returns(client)
        instance.expects(:index_name).returns('foo')
        instance.expects(:document_type).returns('bar')
        instance.expects(:id).returns('1')

        instance.update_document
      end

      should "exclude attributes not contained in custom as_indexed_json during partial update" do
        client   = mock('client')
        instance = ::DummyIndexingModelWithCallbacksAndCustomAsIndexedJson.new

        # Set the fake `changes` hash
        instance.instance_variable_set(:@__changed_attributes, {'foo' => 'B', 'bar' => 'D' })

        client.expects(:update).with do |payload|
          assert_equal({:foo => 'B'}, payload[:body][:doc])
          true
        end

        instance.expects(:client).returns(client)
        instance.expects(:index_name).returns('foo')
        instance.expects(:document_type).returns('bar')
        instance.expects(:id).returns('1')

        instance.update_document
      end

      should "get attributes from as_indexed_json during partial update" do
        client   = mock('client')
        instance = ::DummyIndexingModelWithCallbacksAndCustomAsIndexedJson.new

        instance.instance_variable_set(:@__changed_attributes, { 'foo' => { 'bar' => 'BAR'} })
        # Overload as_indexed_json
        instance.expects(:as_indexed_json).returns({ 'foo' => 'BAR' })

        client.expects(:update).with do |payload|
          assert_equal({'foo' => 'BAR'}, payload[:body][:doc])
          true
        end

        instance.expects(:client).returns(client)
        instance.expects(:index_name).returns('foo')
        instance.expects(:document_type).returns('bar')
        instance.expects(:id).returns('1')

        instance.update_document
      end

      should "update only the specific attributes" do
        client   = mock('client')
        instance = ::DummyIndexingModelWithCallbacks.new

        # Set the fake `changes` hash
        instance.instance_variable_set(:@__changed_attributes, {author: 'john'})

        client.expects(:update).with do |payload|
          assert_equal 'foo',  payload[:index]
          assert_equal 'bar',  payload[:type]
          assert_equal '1',    payload[:id]
          assert_equal({title: 'green'}, payload[:body][:doc])
          true
        end

        instance.expects(:client).returns(client)
        instance.expects(:index_name).returns('foo')
        instance.expects(:document_type).returns('bar')
        instance.expects(:id).returns('1')

        instance.update_document_attributes title: "green"
      end

      should "pass options to the update_document_attributes method" do
        client   = mock('client')
        instance = ::DummyIndexingModelWithCallbacks.new

        client.expects(:update).with do |payload|
          assert_equal 'foo',  payload[:index]
          assert_equal 'bar',  payload[:type]
          assert_equal '1',    payload[:id]
          assert_equal({title: 'green'}, payload[:body][:doc])
          assert_equal true,   payload[:refresh]
          true
        end

        instance.expects(:client).returns(client)
        instance.expects(:index_name).returns('foo')
        instance.expects(:document_type).returns('bar')
        instance.expects(:id).returns('1')

        instance.update_document_attributes( { title: "green" }, { refresh: true } )
      end
    end

    context "Checking for index existence" do
      context "the index exists" do
        should "return true" do
          indices = mock('indices', exists: true)
          client  = stub('client', indices: indices)

          DummyIndexingModelForRecreate.expects(:client).returns(client).at_least_once

          assert_equal true, DummyIndexingModelForRecreate.index_exists?
        end
      end

      context "the index does not exists" do
        should "return false" do
          indices = mock('indices', exists: false)
          client  = stub('client', indices: indices)

          DummyIndexingModelForRecreate.expects(:client).returns(client).at_least_once

          assert_equal false, DummyIndexingModelForRecreate.index_exists?
        end
      end

      context "the indices raises" do
        should "return false" do
          client  = stub('client')
          client.expects(:indices).raises(StandardError)

          DummyIndexingModelForRecreate.expects(:client).returns(client).at_least_once

          assert_equal false, DummyIndexingModelForRecreate.index_exists?
        end
      end

      context "the indices raises" do
        should "return false" do
          indices = stub('indices')
          client  = stub('client')
          client.expects(:indices).returns(indices)

          indices.expects(:exists).raises(StandardError)

          DummyIndexingModelForRecreate.expects(:client).returns(client).at_least_once

          assert_equal false, DummyIndexingModelForRecreate.index_exists?
        end
      end
    end

    context "Re-creating the index" do
      class ::DummyIndexingModelForRecreate
        extend ActiveModel::Naming
        extend Elasticsearch::Model::Naming::ClassMethods
        extend Elasticsearch::Model::Indexing::ClassMethods

        settings index: { number_of_shards: 1 } do
          mappings do
            indexes :foo, analyzer: 'keyword'
          end
        end
      end

      should "delete the index without raising exception when the index is not found" do
        client  = stub('client')
        indices = stub('indices')
        client.stubs(:indices).returns(indices)

        indices.expects(:delete).returns({}).then.raises(NotFound).at_least_once

        DummyIndexingModelForRecreate.expects(:client).returns(client).at_least_once

        assert_nothing_raised { DummyIndexingModelForRecreate.delete_index! force: true }
      end

      should "raise an exception without the force option" do
        client  = stub('client')
        indices = stub('indices')
        client.stubs(:indices).returns(indices)

        indices.expects(:delete).raises(NotFound)

        DummyIndexingModelForRecreate.expects(:client).returns(client)

        assert_raise(NotFound) { DummyIndexingModelForRecreate.delete_index! }
      end

      should "raise a regular exception when deleting the index" do
        client  = stub('client')

        indices = stub('indices')
        indices.expects(:delete).raises(Exception)
        client.stubs(:indices).returns(indices)

        DummyIndexingModelForRecreate.expects(:client).returns(client)

        assert_raise(Exception) { DummyIndexingModelForRecreate.delete_index! force: true }
      end

      should "create the index with correct settings and mappings when it doesn't exist" do
        client  = stub('client')
        indices = stub('indices')
        client.stubs(:indices).returns(indices)

        indices.expects(:create).with do |payload|
          assert_equal 'dummy_indexing_model_for_recreates', payload[:index]
          assert_equal 1,         payload[:body][:settings][:index][:number_of_shards]
          assert_equal 'keyword', payload[:body][:mappings][:dummy_indexing_model_for_recreate][:properties][:foo][:analyzer]
          true
        end.returns({})

        DummyIndexingModelForRecreate.expects(:index_exists?).returns(false)
        DummyIndexingModelForRecreate.expects(:client).returns(client).at_least_once

        assert_nothing_raised { DummyIndexingModelForRecreate.create_index! }
      end

      should "not create the index when it exists" do
        client  = stub('client')
        indices = stub('indices')
        client.stubs(:indices).returns(indices)

        indices.expects(:create).never

        DummyIndexingModelForRecreate.expects(:index_exists?).returns(true)
        DummyIndexingModelForRecreate.expects(:client).returns(client).never

        assert_nothing_raised { DummyIndexingModelForRecreate.create_index! }
      end

      should "raise exception during index creation" do
        client  = stub('client')
        indices = stub('indices')
        client.stubs(:indices).returns(indices)

        indices.expects(:delete).returns({})
        indices.expects(:create).raises(Exception).at_least_once

        DummyIndexingModelForRecreate.expects(:index_exists?).returns(false)
        DummyIndexingModelForRecreate.expects(:client).returns(client).at_least_once

        assert_raise(Exception) { DummyIndexingModelForRecreate.create_index! force: true }
      end

      should "delete the index first with the force option" do
        client  = stub('client')
        indices = stub('indices')
        client.stubs(:indices).returns(indices)

        indices.expects(:delete).returns({})
        indices.expects(:create).returns({}).at_least_once

        DummyIndexingModelForRecreate.expects(:index_exists?).returns(false)
        DummyIndexingModelForRecreate.expects(:client).returns(client).at_least_once

        assert_nothing_raised do
          DummyIndexingModelForRecreate.create_index! force: true
        end
      end

      should "refresh the index without raising exception with the force option" do
        client  = stub('client')
        indices = stub('indices')
        client.stubs(:indices).returns(indices)

        indices.expects(:refresh).returns({}).then.raises(NotFound).at_least_once

        DummyIndexingModelForRecreate.expects(:client).returns(client).at_least_once

        assert_nothing_raised { DummyIndexingModelForRecreate.refresh_index! force: true }
      end

      should "raise a regular exception when refreshing the index" do
        client  = stub('client')
        indices = stub('indices')
        client.stubs(:indices).returns(indices)

        indices.expects(:refresh).returns({}).then.raises(Exception).at_least_once

        DummyIndexingModelForRecreate.expects(:client).returns(client).at_least_once

        assert_nothing_raised { DummyIndexingModelForRecreate.refresh_index! force: true }
      end

      context "with a custom index name" do
        setup do
          @client  = stub('client')
          @indices = stub('indices')
          @client.stubs(:indices).returns(@indices)
          DummyIndexingModelForRecreate.expects(:client).returns(@client).at_least_once
        end

        should "create the custom index" do
          @indices.expects(:create).with do |arguments|
            assert_equal 'custom-foo', arguments[:index]
            true
          end
          DummyIndexingModelForRecreate.expects(:index_exists?).with do |arguments|
            assert_equal 'custom-foo', arguments[:index]
            true
          end

          DummyIndexingModelForRecreate.create_index! index: 'custom-foo'
        end

        should "delete the custom index" do
          @indices.expects(:delete).with do |arguments|
            assert_equal 'custom-foo', arguments[:index]
            true
          end

          DummyIndexingModelForRecreate.delete_index! index: 'custom-foo'
        end

        should "refresh the custom index" do
          @indices.expects(:refresh).with do |arguments|
            assert_equal 'custom-foo', arguments[:index]
            true
          end

          DummyIndexingModelForRecreate.refresh_index! index: 'custom-foo'
        end
      end
    end

  end
end
