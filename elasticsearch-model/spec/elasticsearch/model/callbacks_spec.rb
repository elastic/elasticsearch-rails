require 'spec_helper'

describe Elasticsearch::Model::Callbacks do

  before(:all) do
    class ::DummyCallbacksModel
    end

    module DummyCallbacksAdapter
      module CallbacksMixin
      end

      def callbacks_mixin
        CallbacksMixin
      end; module_function :callbacks_mixin
    end
  end

  after(:all) do
    remove_classes(DummyCallbacksModel, DummyCallbacksAdapter)
  end

  context 'when a model includes the Callbacks module' do

    before do
      Elasticsearch::Model::Callbacks.included(DummyCallbacksModel)
    end

    it 'includes the callbacks mixin from the model adapter' do
      expect(DummyCallbacksModel.ancestors).to include(Elasticsearch::Model::Adapter::Default::Callbacks)
    end
  end
end
