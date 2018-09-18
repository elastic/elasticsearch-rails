require 'spec_helper'

describe Elasticsearch::Model::Adapter::Mongoid do

  before(:all) do
    class DummyClassForMongoid; end
    ::Symbol.class_eval { def in; self; end }
  end

  after(:all) do
    Elasticsearch::Model::Adapter::Adapter.adapters.delete(DummyClassForMongoid)
    remove_classes(DummyClassForMongoid)
  end

  let(:response) do
    { 'hits' => {'hits' => [ {'_id' => 2}, {'_id' => 1} ]} }
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
      allow(rec).to receive(:load).and_return(true)
      allow(rec).to receive(:id).and_return(2)
    end
  end

  let(:records) do
    [record_1, record_2]
  end

  let(:model) do
    DummyClassForMongoid.new.tap do |m|
      allow(m).to receive(:response).and_return(double('response', response: response))
      allow(m).to receive(:ids).and_return(ids)
    end
  end

  describe 'adapter registration' do

    it 'registers an adapater' do
      expect(Elasticsearch::Model::Adapter.adapters[Elasticsearch::Model::Adapter::Mongoid]).not_to be_nil
      expect(Elasticsearch::Model::Adapter.adapters[Elasticsearch::Model::Adapter::Mongoid].call(DummyClassForMongoid)).to be(false)
    end

    it 'registers the records module' do
      expect(Elasticsearch::Model::Adapter::Mongoid::Records).to be_a(Module)
    end
  end

  describe '#records' do

    before(:all) do
      DummyClassForMongoid.__send__ :include, Elasticsearch::Model::Adapter::Mongoid::Records
    end

    let(:instance) do
      model.tap do |inst|
        allow(inst).to receive(:klass).and_return(double('class', where: records)).at_least(:once)
      end
    end

    it 'returns the records' do
      expect(instance.records).to eq(records)
    end

    context 'when an order is not defined for the Mongoid query' do

      context 'when the records have a different order than the hits' do

        before do
          records.instance_variable_set(:@records, records)
        end

        it 'reorders the records based on hits order' do
          expect(records.collect(&:id)).to eq([1, 2])
          expect(instance.records.to_a.collect(&:id)).to eq([2, 1])
        end
      end

      context 'when an order is defined for the Mongoid query' do

        context 'when the records have a different order than the hits' do

          before do
            records.instance_variable_set(:@records, records)
            expect(instance.records).to receive(:asc).and_return(records)
          end

          it 'reorders the records based on hits order' do
            expect(records.collect(&:id)).to eq([1, 2])
            expect(instance.records.to_a.collect(&:id)).to eq([2, 1])
            expect(instance.asc.to_a.collect(&:id)).to eq([1, 2])
          end
        end
      end
    end

    describe 'callbacks registration' do

      before do
        expect(DummyClassForMongoid).to receive(:after_create).once
        expect(DummyClassForMongoid).to receive(:after_update).once
        expect(DummyClassForMongoid).to receive(:after_destroy).once
      end

      it 'should register the model class for callbacks' do
        Elasticsearch::Model::Adapter::Mongoid::Callbacks.included(DummyClassForMongoid)
      end
    end
  end

  describe 'importing' do

    before(:all) do
      DummyClassForMongoid.__send__ :extend, Elasticsearch::Model::Adapter::Mongoid::Importing
    end

    let(:relation) do
      double('relation', each_slice: []).tap do |rel|
        allow(rel).to receive(:published).and_return(rel)
        allow(rel).to receive(:no_timeout).and_return(rel)
        allow(rel).to receive(:class_exec).and_return(rel)
      end
    end

    before do
      allow(DummyClassForMongoid).to receive(:all).and_return(relation)
    end

    context 'when a scope is specified' do

      it 'applies the scope' do
        expect(DummyClassForMongoid.__find_in_batches(scope: :published) do; end).to eq([])
      end
    end

    context 'query criteria specified as a proc' do

      let(:query) do
        Proc.new { where(color: "red") }
      end

      it 'execites the query' do
        expect(DummyClassForMongoid.__find_in_batches(query: query) do; end).to eq([])
      end
    end

    context 'query criteria specified as a hash' do

      before do
        expect(relation).to receive(:where).with(color: 'red').and_return(relation)
      end

      let(:query) do
        { color: "red" }
      end

      it 'execites the query' do
        expect(DummyClassForMongoid.__find_in_batches(query: query) do; end).to eq([])
      end
    end

    context 'when preprocessing batches' do

      context 'if the query returns results' do

        before do
          class << DummyClassForMongoid
            def find_in_batches(options = {}, &block)
              yield [:a, :b]
            end

            def update_batch(batch)
              batch.collect { |b| b.to_s + '!' }
            end
          end
        end

        it 'applies the preprocessing method' do
          DummyClassForMongoid.__find_in_batches(preprocess: :update_batch) do |batch|
            expect(batch).to match(['a!', 'b!'])
          end
        end
      end

      context 'if the query does not return results' do

        before do
          class << DummyClassForMongoid
            def find_in_batches(options = {}, &block)
              yield [:a, :b]
            end

            def update_batch(batch)
              []
            end
          end
        end

        it 'applies the preprocessing method' do
          DummyClassForMongoid.__find_in_batches(preprocess: :update_batch) do |batch|
            expect(batch).to match([])
          end
        end
      end
    end

    context 'when transforming models' do

      let(:instance) do
        model.tap do |inst|
          allow(inst).to receive(:as_indexed_json).and_return({})
          allow(inst).to receive(:id).and_return(1)
        end
      end

      it 'returns an proc' do
        expect(DummyClassForMongoid.__transform.respond_to?(:call)).to be(true)
      end

      it 'provides a default transformation' do
        expect(DummyClassForMongoid.__transform.call(instance)).to eq(index: { _id: '1', data: {} })
      end
    end
  end
end
