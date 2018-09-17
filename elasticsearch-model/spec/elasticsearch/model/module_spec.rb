require 'spec_helper'

describe Elasticsearch::Model do

  describe '#client' do

    it 'should have a default' do
      expect(Elasticsearch::Model.client).to be_a(Elasticsearch::Transport::Client)
    end
  end

  describe '#client=' do

    before do
      Elasticsearch::Model.client = 'Foobar'
    end

    it 'should allow the client to be set' do
      expect(Elasticsearch::Model.client).to eq('Foobar')
    end
  end

  describe 'mixin' do

    before(:all) do
      class ::DummyIncludingModel; end
      class ::DummyIncludingModelWithSearchMethodDefined
        def self.search(query, options={})
          "SEARCH"
        end
      end
    end

    after(:all) do
      Object.send(:remove_const, :DummyIncludingModel) if defined?(DummyIncludingModel)
      Object.send(:remove_const, :DummyIncludingModelWithSearchMethodDefined) if defined?(DummyIncludingModelWithSearchMethodDefined)
    end

    before do
      DummyIncludingModel.__send__ :include, Elasticsearch::Model
    end

    it 'should include and set up the proxy' do
      expect(DummyIncludingModel).to respond_to(:__elasticsearch__)
      expect(DummyIncludingModel.new).to respond_to(:__elasticsearch__)
    end

    it 'should delegate methods to the proxy' do
      expect(DummyIncludingModel).to respond_to(:search)
      expect(DummyIncludingModel).to respond_to(:mapping)
      expect(DummyIncludingModel).to respond_to(:settings)
      expect(DummyIncludingModel).to respond_to(:index_name)
      expect(DummyIncludingModel).to respond_to(:document_type)
      expect(DummyIncludingModel).to respond_to(:import)
    end

    it 'should not interfere with existing methods' do
      expect(DummyIncludingModelWithSearchMethodDefined.search('foo')).to eq('SEARCH')
    end
  end

  describe '#settings' do

    it 'allows access to the settings' do
      expect(Elasticsearch::Model.settings).to eq({})
    end

    context 'when settings are changed' do

      before do
        Elasticsearch::Model.settings[:foo] = 'bar'
      end

      it 'persists the changes' do
        expect(Elasticsearch::Model.settings[:foo]).to eq('bar')
      end
    end
  end
end
