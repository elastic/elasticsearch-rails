require 'spec_helper'

describe Elasticsearch::Model::Adapter::ActiveRecord do

  before(:all) do
    class DummyClassForActiveRecord; end
  end

  after(:all) do
    Elasticsearch::Model::Adapter::Adapter.adapters.delete(DummyClassForActiveRecord)
    remove_classes(DummyClassForActiveRecord)
  end

  let(:model) do
    DummyClassForActiveRecord.new.tap do |m|
      allow(m).to receive(:response).and_return(double('response', response: response))
      allow(m).to receive(:ids).and_return(ids)
    end
  end

  let(:response) do
    { 'hits' => {'hits' => [ {'_id' => 2 }, {'_id' => 1 } ]} }
  end

  let(:ids) do
    [2, 1]
  end

  let(:record_1) do
    double('record').tap do |rec|
      allow(rec).to receive(:id).and_return(1)
    end
  end

  let(:record_2) do
    double('record').tap do |rec|
      allow(rec).to receive(:id).and_return(2)
    end
  end

  let(:records) do
    [record_1, record_2].tap do |r|
      allow(r).to receive(:load).and_return(true)
      allow(r).to receive(:exec_queries).and_return(true)
    end
  end

  describe 'adapter registration' do

    before(:all) do
      DummyClassForActiveRecord.__send__ :include, Elasticsearch::Model::Adapter::ActiveRecord::Records
    end

    it 'can register an adapater' do
      expect(Elasticsearch::Model::Adapter.adapters[Elasticsearch::Model::Adapter::ActiveRecord]).not_to be_nil
      expect(Elasticsearch::Model::Adapter.adapters[Elasticsearch::Model::Adapter::ActiveRecord].call(DummyClassForActiveRecord)).to be(false)
    end
  end

  describe '#records' do

    before(:all) do
      DummyClassForActiveRecord.__send__ :include, Elasticsearch::Model::Adapter::ActiveRecord::Records
    end

    let(:instance) do
      model.tap do |inst|
        allow(inst).to receive(:klass).and_return(double('class', primary_key: :some_key, where: records)).at_least(:once)
        allow(inst).to receive(:order).and_return(double('class', primary_key: :some_key, where: records)).at_least(:once)
      end
    end

    it 'returns the list of records' do
      expect(instance.records).to eq(records)
    end

    it 'loads the records' do
      expect(instance.load).to eq(true)
    end

    context 'when :includes is specified' do

      before do
        expect(records).to receive(:includes).with([:submodel]).once.and_return(records)
        instance.options[:includes] = [:submodel]
      end

      it 'incorporates the includes option in the query' do
        expect(instance.records).to eq(records)
      end
    end
  end

  describe 'callbacks registration' do

    before do
      expect(DummyClassForActiveRecord).to receive(:after_commit).exactly(3).times
    end

    it 'should register the model class for callbacks' do
      Elasticsearch::Model::Adapter::ActiveRecord::Callbacks.included(DummyClassForActiveRecord)
    end
  end

  describe 'importing' do

    before do
      DummyClassForActiveRecord.__send__ :extend, Elasticsearch::Model::Adapter::ActiveRecord::Importing
    end

    context 'when an invalid scope is specified' do

      it 'raises a NoMethodError' do
        expect {
          DummyClassForActiveRecord.__find_in_batches(scope: :not_found_method)
        }.to raise_exception(NoMethodError)
      end
    end

    context 'when a valid scope is specified' do

      before do
        expect(DummyClassForActiveRecord).to receive(:find_in_batches).once.and_return([])
        expect(DummyClassForActiveRecord).to receive(:published).once.and_return(DummyClassForActiveRecord)
      end

      it 'uses the scope' do
        expect(DummyClassForActiveRecord.__find_in_batches(scope: :published)).to eq([])
      end
    end

    context 'allow query criteria to be specified' do

      before do
        expect(DummyClassForActiveRecord).to receive(:find_in_batches).once.and_return([])
        expect(DummyClassForActiveRecord).to receive(:where).with(color: 'red').once.and_return(DummyClassForActiveRecord)
      end

      it 'uses the scope' do
        expect(DummyClassForActiveRecord.__find_in_batches(query: -> { where(color: 'red') })).to eq([])
      end
    end

    context 'when preprocessing batches' do

      context 'if the query returns results' do

        before do
          class << DummyClassForActiveRecord
            def find_in_batches(options = {}, &block)
              yield [:a, :b]
            end

            def update_batch(batch)
              batch.collect { |b| b.to_s + '!' }
            end
          end
        end

        it 'applies the preprocessing method' do
          DummyClassForActiveRecord.__find_in_batches(preprocess: :update_batch) do |batch|
            expect(batch).to match(['a!', 'b!'])
          end
        end
      end

      context 'if the query does not return results' do

        before do
          class << DummyClassForActiveRecord
            def find_in_batches(options = {}, &block)
              yield [:a, :b]
            end

            def update_batch(batch)
              []
            end
          end
        end

        it 'applies the preprocessing method' do
          DummyClassForActiveRecord.__find_in_batches(preprocess: :update_batch) do |batch|
            expect(batch).to match([])
          end
        end
      end
    end

    context 'when transforming models' do

      let(:instance) do
        model.tap do |inst|
          allow(inst).to receive(:id).and_return(1)
          allow(inst).to receive(:__elasticsearch__).and_return(double('object', id: 1, as_indexed_json: {}))
        end
      end

      it 'returns an proc' do
        expect(DummyClassForActiveRecord.__transform.respond_to?(:call)).to be(true)
      end

      it 'provides a default transformation' do
        expect(DummyClassForActiveRecord.__transform.call(instance)).to eq(index: { _id: 1, data: {} })
      end
    end
  end
end
