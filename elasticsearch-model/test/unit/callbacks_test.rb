require 'test_helper'

class Elasticsearch::Model::CallbacksTest < Test::Unit::TestCase
  context "Callbacks module" do
    class ::DummyCallbacksModel
    end

    module DummyCallbacksAdapter
      module CallbacksMixin
      end

      def callbacks_mixin
        CallbacksMixin
      end; module_function :callbacks_mixin
    end

    should "include the callbacks mixin from adapter" do
      Elasticsearch::Model::Adapter.expects(:from_class)
                                   .with(DummyCallbacksModel)
                                   .returns(DummyCallbacksAdapter)

      ::DummyCallbacksModel.expects(:__send__).with do |method, parameter|
        assert_equal :include, method
        assert_equal DummyCallbacksAdapter::CallbacksMixin, parameter
      end

      Elasticsearch::Model::Callbacks.included(DummyCallbacksModel)
    end
  end
end
