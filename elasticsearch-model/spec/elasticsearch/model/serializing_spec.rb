require 'spec_helper'

describe Elasticsearch::Model::Serializing do

  before(:all) do
    class DummyClass
      include Elasticsearch::Model::Serializing::InstanceMethods

      def as_json(options={})
        'HASH'
      end
    end
  end

  after(:all) do
    remove_classes(DummyClass)
  end

  it 'delegates to #as_json by default' do
    expect(DummyClass.new.as_indexed_json).to eq('HASH')
  end
end
