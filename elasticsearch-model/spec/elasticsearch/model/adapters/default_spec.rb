require 'spec_helper'

describe Elasticsearch::Model::Adapter::Default do

  before(:all) do
    class DummyClassForDefaultAdapter; end
    DummyClassForDefaultAdapter.__send__ :include, Elasticsearch::Model::Adapter::Default::Records
    DummyClassForDefaultAdapter.__send__ :include, Elasticsearch::Model::Adapter::Default::Importing
  end

  after(:all) do
    Elasticsearch::Model::Adapter::Adapter.adapters.delete(DummyClassForDefaultAdapter)
    Object.send(:remove_const, :DummyClassForDefaultAdapter) if defined?(DummyClassForDefaultAdapter)
  end

  let(:instance) do
    DummyClassForDefaultAdapter.new.tap do |m|
      allow(m).to receive(:klass).and_return(double('class', primary_key: :some_key, find: [1])).at_least(:once)
    end
  end

  it 'should have the default records implementation' do
    expect(instance.records).to eq([1])
  end

  it 'should have the default Callback implementation' do
    expect(Elasticsearch::Model::Adapter::Default::Callbacks).to be_a(Module)
  end

  it 'should have the default Importing implementation' do
    expect {
      DummyClassForDefaultAdapter.new.__find_in_batches
    }.to raise_exception(Elasticsearch::Model::NotImplemented)
  end

  it 'should have the default transform implementation' do
    expect {
      DummyClassForDefaultAdapter.new.__transform
    }.to raise_exception(Elasticsearch::Model::NotImplemented)
  end
end
