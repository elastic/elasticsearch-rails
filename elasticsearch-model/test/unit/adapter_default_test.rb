require 'test_helper'

class Elasticsearch::Model::AdapterDefaultTest < Test::Unit::TestCase
  context "Adapter default module" do
    class ::DummyClassForDefaultAdapter; end

    should "have the default Records implementation" do
      assert_instance_of Module, Elasticsearch::Model::Adapter::Default::Records

      DummyClassForDefaultAdapter.__send__ :include, Elasticsearch::Model::Adapter::Default::Records

      instance = DummyClassForDefaultAdapter.new
      klass = mock('class', find: [1])
      instance.expects(:klass).returns(klass)
      instance.records
    end

    should "have the default Callbacks implementation" do
      assert_instance_of Module, Elasticsearch::Model::Adapter::Default::Callbacks
    end

    context "concerning abstract methods" do
      setup do
        DummyClassForDefaultAdapter.__send__ :include, Elasticsearch::Model::Adapter::Default::Importing
      end

      should "have the default Importing implementation" do
        assert_raise Elasticsearch::Model::NotImplemented do
          DummyClassForDefaultAdapter.new.__find_in_batches
        end
      end

      should "have the default transform implementation" do
        assert_raise Elasticsearch::Model::NotImplemented do
          DummyClassForDefaultAdapter.new.__transform
        end
      end
    end

  end
end
