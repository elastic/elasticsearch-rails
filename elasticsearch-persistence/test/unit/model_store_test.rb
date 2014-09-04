require 'test_helper'

require 'active_model'
require 'virtus'

require 'elasticsearch/persistence/model/base'
require 'elasticsearch/persistence/model/errors'
require 'elasticsearch/persistence/model/store'

class Elasticsearch::Persistence::ModelStoreTest < Test::Unit::TestCase
  context "The model store module," do

    class DummyStoreModel
      include ActiveModel::Naming
      include ActiveModel::Conversion
      include ActiveModel::Serialization
      include ActiveModel::Serializers::JSON
      include ActiveModel::Validations

      include Virtus.model

      include Elasticsearch::Persistence::Model::Base::InstanceMethods
      extend  Elasticsearch::Persistence::Model::Store::ClassMethods
      include Elasticsearch::Persistence::Model::Store::InstanceMethods

      extend  ActiveModel::Callbacks
      define_model_callbacks :create, :save, :update, :destroy
      define_model_callbacks :find, :touch, only: :after

      attribute :title, String
      attribute :count, Integer, default: 0
      attribute :created_at, DateTime, default: lambda { |o,a| Time.now.utc }
      attribute :updated_at, DateTime, default: lambda { |o,a| Time.now.utc }
    end

    setup do
      @shoulda_subject = DummyStoreModel.new title: 'Test'
      @gateway         = stub
      DummyStoreModel.stubs(:gateway).returns(@gateway)
    end

    teardown do
      Elasticsearch::Persistence::ModelStoreTest.__send__ :remove_const, :DummyStoreModelWithCallback \
      rescue NameError; nil
    end

    should "be new_record" do
      assert subject.new_record?
    end

    context "when creating," do
      should "save the object and return it" do
        DummyStoreModel.any_instance.expects(:save).returns({'_id' => 'X'})

        assert_instance_of DummyStoreModel, DummyStoreModel.create(title: 'Test')
      end

      should "execute the callbacks" do
        DummyStoreModelWithCallback = Class.new(DummyStoreModel)
        @gateway.expects(:save).returns({'_id' => 'X'})

        DummyStoreModelWithCallback.after_create { $stderr.puts "CREATED" }
        DummyStoreModelWithCallback.after_save   { $stderr.puts "SAVED"   }

        $stderr.expects(:puts).with('CREATED')
        $stderr.expects(:puts).with('SAVED')

        DummyStoreModelWithCallback.create name: 'test'
      end
    end

    context "when saving," do
      should "save the model" do
        @gateway
          .expects(:save)
          .with do |object, options|
            assert_equal subject, object
            assert_equal nil, options[:id]
            true
          end
          .returns({'_id' => 'abc123'})

        assert ! subject.persisted?

        assert subject.save
        assert subject.persisted?
      end

      should "save the model and set the ID" do
        @gateway
          .expects(:save)
          .returns({'_id' => 'abc123'})

        assert_nil subject.id

        subject.save
        assert_equal 'abc123', subject.id
      end

      should "save the model and update the timestamp" do
        now = Time.parse('2014-01-01T00:00:00Z')
        Time.expects(:now).returns(now).at_least_once
        @gateway
          .expects(:save)
          .returns({'_id' => 'abc123'})

        subject.save
        assert_equal Time.parse('2014-01-01T00:00:00Z'), subject.updated_at
      end

      should "pass the options to gateway" do
        @gateway
          .expects(:save)
          .with do |object, options|
            assert_equal 'ABC', options[:routing]
            true
          end
          .returns({'_id' => 'abc123'})

        assert subject.save routing: 'ABC'
      end

      should "return the response" do
         @gateway
          .expects(:save)
          .returns('FOOBAR')

        assert_equal 'FOOBAR', subject.save
      end

      should "execute the callbacks" do
        @gateway.expects(:save).returns({'_id' => 'abc'})
        DummyStoreModelWithCallback = Class.new(DummyStoreModel)

        DummyStoreModelWithCallback.after_save { $stderr.puts "SAVED" }

        $stderr.expects(:puts).with('SAVED')
        d = DummyStoreModelWithCallback.new name: 'Test'
        d.save
      end

      should "save the model to its own index" do
        @gateway.expects(:save)
          .with do |model, options|
            assert_equal 'my_custom_index', options[:index]
            assert_equal 'my_custom_type',  options[:type]
            true
          end
          .returns({'_id' => 'abc'})

        d = DummyStoreModel.new name: 'Test'
        d.instance_variable_set(:@_index, 'my_custom_index')
        d.instance_variable_set(:@_type,  'my_custom_type')
        d.save
      end

      should "set the meta attributes from response" do
        @gateway.expects(:save)
          .with do |model, options|
            assert_equal 'my_custom_index', options[:index]
            assert_equal 'my_custom_type',  options[:type]
            true
          end
          .returns({'_id' => 'abc', '_index' => 'foo', '_type' => 'bar', '_version' => '100'})

        d = DummyStoreModel.new name: 'Test'
        d.instance_variable_set(:@_index, 'my_custom_index')
        d.instance_variable_set(:@_type,  'my_custom_type')
        d.save

        assert_equal 'foo', d._index
        assert_equal 'bar', d._type
        assert_equal '100', d._version
      end
    end

    context "when destroying," do
      should "remove the model from Elasticsearch" do
        subject.expects(:persisted?).returns(true)
        subject.expects(:id).returns('abc123')
        subject.expects(:freeze).returns(subject)

        @gateway
          .expects(:delete)
          .with('abc123', {})
          .returns({'_id' => 'abc123', 'version' => 2})

        assert subject.destroy
        assert subject.destroyed?
      end

      should "pass the options to gateway" do
        subject.expects(:persisted?).returns(true)
        subject.expects(:freeze).returns(subject)

        @gateway
          .expects(:delete)
          .with do |object, options|
            assert_equal 'ABC', options[:routing]
            true
          end
          .returns({'_id' => 'abc123'})

        assert subject.destroy routing: 'ABC'
      end

      should "return the response" do
        subject.expects(:persisted?).returns(true)
        subject.expects(:freeze).returns(subject)

        @gateway
          .expects(:delete)
          .returns('FOOBAR')

        assert_equal 'FOOBAR', subject.destroy
      end

      should "execute the callbacks" do
        @gateway.expects(:delete).returns({'_id' => 'abc'})
        DummyStoreModelWithCallback = Class.new(DummyStoreModel)

        DummyStoreModelWithCallback.after_destroy { $stderr.puts "DELETED" }

        $stderr.expects(:puts).with('DELETED')
        d = DummyStoreModelWithCallback.new name: 'Test'
        d.expects(:persisted?).returns(true)
        d.expects(:freeze).returns(d)

        d.destroy
      end

      should "remove the model from its own index" do
        @gateway.expects(:delete)
          .with do |model, options|
            assert_equal 'my_custom_index', options[:index]
            assert_equal 'my_custom_type',  options[:type]
            true
          end
          .returns({'_id' => 'abc'})

        d = DummyStoreModel.new name: 'Test'
        d.instance_variable_set(:@_index, 'my_custom_index')
        d.instance_variable_set(:@_type,  'my_custom_type')
        d.expects(:persisted?).returns(true)
        d.expects(:freeze).returns(d)

        d.destroy
      end
    end

    context "when updating," do
      should "update the document with partial attributes" do
        subject.expects(:persisted?).returns(true)
        subject.expects(:id).returns('abc123').at_least_once

        @gateway
          .expects(:update)
          .with do |id, options|
            assert_equal 'abc123', id
            assert_equal 'UPDATED', options[:doc][:title]
            true
          end
          .returns({'_id' => 'abc123', 'version' => 2})

        assert subject.update title: 'UPDATED'

        assert_equal 'UPDATED', subject.title
      end

      should "allow to update the document with a custom script" do
        subject.expects(:persisted?).returns(true)
        subject.expects(:id).returns('abc123').at_least_once

        @gateway
          .expects(:update)
          .with do |id, options|
            assert_equal 'abc123', id
            assert_equal 'EXEC', options[:script]
            true
          end
          .returns({'_id' => 'abc123', 'version' => 2})

        assert subject.update( {}, { script: 'EXEC' } )
      end

      should "pass the options to gateway" do
        subject.expects(:persisted?).returns(true)

        @gateway
          .expects(:update)
          .with do |object, options|
            assert_equal 'ABC', options[:routing]
            true
          end
          .returns({'_id' => 'abc123'})

        assert subject.update( { title: 'UPDATED' }, { routing: 'ABC' } )
      end

      should "return the response" do
        subject.expects(:persisted?).returns(true)

        @gateway
          .expects(:update)
          .returns('FOOBAR')

        assert_equal 'FOOBAR', subject.update
      end

      should "execute the callbacks" do
        @gateway.expects(:update).returns({'_id' => 'abc'})
        DummyStoreModelWithCallback = Class.new(DummyStoreModel)

        DummyStoreModelWithCallback.after_update { $stderr.puts "UPDATED" }

        $stderr.expects(:puts).with('UPDATED')
        d = DummyStoreModelWithCallback.new name: 'Test'
        d.expects(:persisted?).returns(true)
        d.update name: 'Update'
      end

      should "update the model in its own index" do
        @gateway.expects(:update)
          .with do |model, options|
            assert_equal 'my_custom_index', options[:index]
            assert_equal 'my_custom_type',  options[:type]
            true
          end
          .returns({'_id' => 'abc'})

        d = DummyStoreModel.new name: 'Test'
        d.instance_variable_set(:@_index, 'my_custom_index')
        d.instance_variable_set(:@_type,  'my_custom_type')
        d.expects(:persisted?).returns(true)

        d.update name: 'Update'
      end

      should "set the meta attributes from response" do
        @gateway.expects(:update)
          .with do |model, options|
            assert_equal 'my_custom_index', options[:index]
            assert_equal 'my_custom_type',  options[:type]
            true
          end
          .returns({'_id' => 'abc', '_index' => 'foo', '_type' => 'bar', '_version' => '100'})

        d = DummyStoreModel.new name: 'Test'
        d.instance_variable_set(:@_index, 'my_custom_index')
        d.instance_variable_set(:@_type,  'my_custom_type')
        d.expects(:persisted?).returns(true)

        d.update name: 'Update'

        assert_equal 'foo', d._index
        assert_equal 'bar', d._type
        assert_equal '100', d._version
      end
    end

    context "when incrementing," do
      should "increment the attribute" do
        subject.expects(:persisted?).returns(true)

        @gateway
          .expects(:update)
          .with do |id, options|
            assert_equal 'ctx._source.count += 1', options[:script]
            true
          end
          .returns({'_id' => 'abc123', 'version' => 2})

        assert subject.increment :count

        assert_equal 1, subject.count
      end

      should "set the meta attributes from response" do
        subject.expects(:persisted?).returns(true)

        @gateway.expects(:update)
          .with do |model, options|
            assert_equal 'my_custom_index', options[:index]
            assert_equal 'my_custom_type',  options[:type]
            true
          end
          .returns({'_id' => 'abc', '_index' => 'foo', '_type' => 'bar', '_version' => '100'})

        subject.instance_variable_set(:@_index, 'my_custom_index')
        subject.instance_variable_set(:@_type,  'my_custom_type')

        subject.increment :count

        assert_equal 'foo', subject._index
        assert_equal 'bar', subject._type
        assert_equal '100', subject._version
      end
    end

    context "when decrement," do
      should "decrement the attribute" do
        subject.expects(:persisted?).returns(true)

        @gateway
          .expects(:update)
          .with do |id, options|
            assert_equal 'ctx._source.count = ctx._source.count - 1', options[:script]
            true
          end
          .returns({'_id' => 'abc123', 'version' => 2})

        assert subject.decrement :count

        assert_equal -1, subject.count
      end

      should "set the meta attributes from response" do
        subject.expects(:persisted?).returns(true)

        @gateway.expects(:update)
          .with do |model, options|
            assert_equal 'my_custom_index', options[:index]
            assert_equal 'my_custom_type',  options[:type]
            true
          end
          .returns({'_id' => 'abc', '_index' => 'foo', '_type' => 'bar', '_version' => '100'})

        subject.instance_variable_set(:@_index, 'my_custom_index')
        subject.instance_variable_set(:@_type,  'my_custom_type')

        subject.decrement :count

        assert_equal 'foo', subject._index
        assert_equal 'bar', subject._type
        assert_equal '100', subject._version
      end
    end

    context "when touching," do
      should "raise exception when touching not existing attribute" do
        subject.expects(:persisted?).returns(true)
        assert_raise(ArgumentError) { subject.touch :foobar }
      end

      should "update updated_at by default" do
        subject.expects(:persisted?).returns(true)
        now = Time.parse('2014-01-01T00:00:00Z')
        Time.expects(:now).returns(now).at_least_once

        @gateway
          .expects(:update)
          .with do |id, options|
            assert_equal '2014-01-01T00:00:00Z', options[:doc][:updated_at]
            true
          end
          .returns({'_id' => 'abc123', 'version' => 2})

        subject.touch
        assert_equal Time.parse('2014-01-01T00:00:00Z'), subject.updated_at
      end

      should "update a custom attribute by default" do
        subject.expects(:persisted?).returns(true)
        now = Time.parse('2014-01-01T00:00:00Z')
        Time.expects(:now).returns(now).at_least_once

        @gateway
          .expects(:update)
          .with do |id, options|
            assert_equal '2014-01-01T00:00:00Z', options[:doc][:created_at]
            true
          end
          .returns({'_id' => 'abc123', 'version' => 2})

        subject.touch :created_at
        assert_equal Time.parse('2014-01-01T00:00:00Z'), subject.created_at
      end

      should "execute the callbacks" do
        @gateway.expects(:update).returns({'_id' => 'abc'})
        DummyStoreModelWithCallback = Class.new(DummyStoreModel)

        DummyStoreModelWithCallback.after_touch { $stderr.puts "TOUCHED" }

        $stderr.expects(:puts).with('TOUCHED')
        d = DummyStoreModelWithCallback.new name: 'Test'
        d.expects(:persisted?).returns(true)
        d.touch
      end

      should "set the meta attributes from response" do
        subject.expects(:persisted?).returns(true)

        @gateway.expects(:update)
          .with do |model, options|
            assert_equal 'my_custom_index', options[:index]
            assert_equal 'my_custom_type',  options[:type]
            true
          end
          .returns({'_id' => 'abc', '_index' => 'foo', '_type' => 'bar', '_version' => '100'})

        subject.instance_variable_set(:@_index, 'my_custom_index')
        subject.instance_variable_set(:@_type,  'my_custom_type')

        subject.touch

        assert_equal 'foo', subject._index
        assert_equal 'bar', subject._type
        assert_equal '100', subject._version
      end
    end

  end
end
