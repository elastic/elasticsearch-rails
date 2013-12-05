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

      should "update and return the index settings" do
        DummyIndexingModel.settings foo: 'boo'
        DummyIndexingModel.settings bar: 'bam'

        assert_equal( {foo: 'boo', bar: 'bam'},  DummyIndexingModel.settings.to_hash)
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

      should "define embedded properties" do
        mappings = Elasticsearch::Model::Indexing::Mappings.new :mytype

        mappings.indexes :foo do
          indexes :bar
        end

        assert_equal 'object', mappings.to_hash[:mytype][:properties][:foo][:type]
        assert_equal 'string', mappings.to_hash[:mytype][:properties][:foo][:properties][:bar][:type]
      end
    end

    context "Mappings method" do
      should "initialize the index mappings" do
        assert_instance_of Elasticsearch::Model::Indexing::Mappings, DummyIndexingModel.mappings
      end

      should "update and return the index mappings" do
        DummyIndexingModel.mappings foo: 'boo' do; end
        DummyIndexingModel.mappings bar: 'bam' do; end
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

      should "register before_save callback when included" do
        ::DummyIndexingModelWithCallbacks.expects(:before_save).returns(true)
        ::DummyIndexingModelWithCallbacks.__send__ :include, Elasticsearch::Model::Indexing::InstanceMethods
      end

      should "set the @__changed_attributes variable before save" do
        instance = ::DummyIndexingModelWithCallbacks.new
        instance.expects(:instance_variable_set).with do |name, value|
          assert_equal :@__changed_attributes, name
          assert_equal({foo: 'Two'}, value)
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
        end

        instance.expects(:client).returns(client)
        instance.expects(:index_name).returns('foo')
        instance.expects(:document_type).returns('bar')
        instance.expects(:id).returns('1')

        instance.update_document
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

      should "delete the index without raising exception" do
        client  = stub('client')
        indices = stub('indices')
        client.stubs(:indices).returns(indices)

        indices.expects(:delete).returns({}).then.raises(Exception).at_least_once

        DummyIndexingModelForRecreate.expects(:client).returns(client).at_least_once

        assert_nothing_raised do
          DummyIndexingModelForRecreate.delete_index!
          DummyIndexingModelForRecreate.delete_index!
        end
      end

      should "create the index with correct settings and mappings when it doesn't exist" do
        client  = stub('client')
        indices = stub('indices')
        client.stubs(:indices).returns(indices)

        indices.expects(:exists).returns(false)

        indices.expects(:create).with do |payload|
          assert_equal 'dummy_indexing_model_for_recreates', payload[:index]
          assert_equal 1,         payload[:body][:settings][:index][:number_of_shards]
          assert_equal 'keyword', payload[:body][:mappings][:dummy_indexing_model_for_recreate][:properties][:foo][:analyzer]
        end.returns({})

        DummyIndexingModelForRecreate.expects(:client).returns(client).at_least_once

        assert_nothing_raised { DummyIndexingModelForRecreate.create_index! }
      end

      should "not create the index when it exists" do
        client  = stub('client')
        indices = stub('indices')
        client.stubs(:indices).returns(indices)

        indices.expects(:exists).returns(true)

        indices.expects(:create).never

        DummyIndexingModelForRecreate.expects(:client).returns(client).at_least_once

        assert_nothing_raised { DummyIndexingModelForRecreate.create_index! }
      end

      should "not raise exception during index creation" do
        client  = stub('client')
        indices = stub('indices')
        client.stubs(:indices).returns(indices)

        indices.expects(:exists).returns(false)
        indices.expects(:create).raises(Exception).at_least_once

        DummyIndexingModelForRecreate.expects(:client).returns(client).at_least_once

        assert_nothing_raised do
          DummyIndexingModelForRecreate.create_index!
        end
      end

      should "delete the index first with the force option" do
        client  = stub('client')
        indices = stub('indices')
        client.stubs(:indices).returns(indices)

        indices.expects(:delete).returns({})
        indices.expects(:exists).returns(false)
        indices.expects(:create).returns({}).at_least_once

        DummyIndexingModelForRecreate.expects(:client).returns(client).at_least_once

        assert_nothing_raised do
          DummyIndexingModelForRecreate.create_index! force: true
        end
      end

      should "refresh the index without raising exception" do
        client  = stub('client')
        indices = stub('indices')
        client.stubs(:indices).returns(indices)

        indices.expects(:refresh).returns({}).then.raises(Exception).at_least_once

        DummyIndexingModelForRecreate.expects(:client).returns(client).at_least_once

        assert_nothing_raised do
          DummyIndexingModelForRecreate.refresh_index!
          DummyIndexingModelForRecreate.refresh_index!
        end
      end
    end

  end
end
