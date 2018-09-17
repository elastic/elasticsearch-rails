require 'spec_helper'

describe Elasticsearch::Model::Proxy do

  before(:all) do
    class ::DummyProxyModel
      include Elasticsearch::Model::Proxy

      def self.foo
        'classy foo'
      end

      def bar
        'insta barr'
      end

      def as_json(options)
        {foo: 'bar'}
      end
    end

    class ::DummyProxyModelWithCallbacks
      def self.before_save(&block)
        (@callbacks ||= {})[block.hash] = block
      end

      def changes_to_save
        {:foo => ['One', 'Two']}
      end
    end
  end

  after(:all) do
    Object.send(:remove_const, :DummyProxyModel) if defined?(DummyProxyModel)
    Object.send(:remove_const, :DummyProxyModelWithCallbacks) if defined?(DummyProxyModelWithCallbacks)
  end

  before do
    DummyProxyModelWithCallbacks.__send__ :include, Elasticsearch::Model::Proxy
  end

  it 'sets up a proxy method on the class' do
    expect(DummyProxyModel).to respond_to(:__elasticsearch__)
  end

  it 'sets up a proxy method on instances' do
    expect(DummyProxyModel.new).to respond_to(:__elasticsearch__)
  end

  it 'sets up hooks for before_save callbacks' do
    expect(DummyProxyModelWithCallbacks).to respond_to(:before_save)
  end

  it 'delegates methods to the target' do
    expect(DummyProxyModel.__elasticsearch__).to respond_to(:foo)
    expect(DummyProxyModel.__elasticsearch__.foo).to eq('classy foo')
    expect(DummyProxyModel.new.__elasticsearch__).to respond_to(:bar)
    expect(DummyProxyModel.new.__elasticsearch__.bar).to eq('insta barr')

    expect {
      DummyProxyModel.__elasticsearch__.xoxo
    }.to raise_exception(NoMethodError)

    expect {
      DummyProxyModel.new.__elasticsearch__.xoxo
    }.to raise_exception(NoMethodError)
  end

  it 'returns the proxy class from an instance proxy' do
    expect(DummyProxyModel.new.__elasticsearch__.class.class).to eq(Elasticsearch::Model::Proxy::ClassMethodsProxy)
  end

  it 'returns the origin class from an instance proxy' do
    expect(DummyProxyModel.new.__elasticsearch__.klass).to eq(DummyProxyModel)
  end

  it 'delegates #as_json from the proxy to the target' do
    expect(DummyProxyModel.new.__elasticsearch__.as_json).to eq(foo: 'bar')
  end

  it 'includes the proxy in the inspect string' do
    expect(DummyProxyModel.__elasticsearch__.inspect).to match(/PROXY/)
    expect(DummyProxyModel.new.__elasticsearch__.inspect).to match(/PROXY/)
  end

  context 'when instances are cloned' do

    let!(:model) do
      DummyProxyModel.new
    end

    let!(:model_target) do
      model.__elasticsearch__.target
    end

    let!(:duplicate) do
      model.dup
    end

    let!(:duplicate_target) do
      duplicate.__elasticsearch__.target
    end

    it 'resets the proxy target' do
      expect(model).not_to eq(duplicate)
      expect(model).to eq(model_target)
      expect(duplicate).to eq(duplicate_target)
    end
  end
end
