require 'spec_helper'

describe Elasticsearch::Model::Multimodel do

  let(:multimodel) do
    Elasticsearch::Model::Multimodel.new(model_1, model_2)
  end

  let(:model_1) do
    double('Foo', index_name: 'foo_index', document_type: 'foo', to_ary: nil)
  end

  let(:model_2) do
    double('Bar', index_name: 'bar_index', document_type: 'bar', to_ary: nil)
  end

  it 'has an index name' do
    expect(multimodel.index_name).to eq(['foo_index', 'bar_index'])
  end

  it 'has an document type' do
    expect(multimodel.document_type).to eq(['foo', 'bar'])
  end

  it 'has a client' do
    expect(multimodel.client).to eq(Elasticsearch::Model.client)
  end

  describe 'the model registry' do

    before(:all) do

      class JustAModel
        include Elasticsearch::Model
      end

      class JustAnotherModel
        include Elasticsearch::Model
      end
    end

    after(:all) do
      Object.send(:remove_const, :JustAModel) if defined?(JustAModel)
      Object.send(:remove_const, :JustAnotherModel) if defined?(JustAnotherModel)
    end

    let(:multimodel) do
      Elasticsearch::Model::Multimodel.new
    end

    it 'includes model in the registry' do
      expect(multimodel.models).to include(JustAModel)
      expect(multimodel.models).to include(JustAnotherModel)
    end
  end
end
