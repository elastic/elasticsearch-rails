require 'test_helper'

class Elasticsearch::Model::AdapterTest < Test::Unit::TestCase
  context "Adapter module" do
    class ::DummyAdapterClass; end
    class ::DummyAdapterClassWithAdapter; end
    class ::DummyAdapter
      Records   = Module.new
      Callbacks = Module.new
      Importing = Module.new
    end

    should "return an Adapter instance" do
      assert_instance_of Elasticsearch::Model::Adapter::Adapter,
                         Elasticsearch::Model::Adapter.from_class(DummyAdapterClass)
    end

    should "return a list of adapters" do
      Elasticsearch::Model::Adapter::Adapter.expects(:adapters)
      Elasticsearch::Model::Adapter.adapters
    end

    should "register an adapter" do
      begin
        Elasticsearch::Model::Adapter::Adapter.expects(:register)
        Elasticsearch::Model::Adapter.register(:foo, lambda { |c| false })
      ensure
        Elasticsearch::Model::Adapter::Adapter.instance_variable_set(:@adapters, {})
      end
    end
  end

  context "Adapter class" do
    should "register an adapter" do
      begin
        Elasticsearch::Model::Adapter::Adapter.register(:foo, lambda { |c| false })
        assert Elasticsearch::Model::Adapter::Adapter.adapters[:foo]
      ensure
        Elasticsearch::Model::Adapter::Adapter.instance_variable_set(:@adapters, {})
      end
    end

    should "return the default adapter" do
      adapter = Elasticsearch::Model::Adapter::Adapter.new(DummyAdapterClass)
      assert_equal Elasticsearch::Model::Adapter::Default, adapter.adapter
    end

    should "return a specific adapter" do
      Elasticsearch::Model::Adapter::Adapter.register(DummyAdapter,
                                                      lambda { |c| c == DummyAdapterClassWithAdapter })

      adapter = Elasticsearch::Model::Adapter::Adapter.new(DummyAdapterClassWithAdapter)
      assert_equal DummyAdapter, adapter.adapter
    end

    should "return the modules" do
      assert_nothing_raised do
        Elasticsearch::Model::Adapter::Adapter.register(DummyAdapter,
                                                      lambda { |c| c == DummyAdapterClassWithAdapter })

        adapter = Elasticsearch::Model::Adapter::Adapter.new(DummyAdapterClassWithAdapter)

        assert_instance_of Module, adapter.records_mixin
        assert_instance_of Module, adapter.callbacks_mixin
        assert_instance_of Module, adapter.importing_mixin
      end
    end
  end
end
