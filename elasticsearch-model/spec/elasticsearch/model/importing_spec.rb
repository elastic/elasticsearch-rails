require 'spec_helper'

describe Elasticsearch::Model::Importing do

  before(:all) do
    class DummyImportingModel
    end

    module DummyImportingAdapter
      module ImportingMixin
        def __find_in_batches(options={}, &block)
          yield if block_given?
        end
        def __transform
          lambda {|a|}
        end
      end

      def importing_mixin
        ImportingMixin
      end; module_function :importing_mixin
    end
  end

  after(:all) do
    remove_classes(DummyImportingModel, DummyImportingAdapter)
  end

  before do
    allow(Elasticsearch::Model::Adapter).to receive(:from_class).with(DummyImportingModel).and_return(DummyImportingAdapter)
    DummyImportingModel.__send__ :include, Elasticsearch::Model::Importing
  end

  context 'when a model includes the Importing module' do

    it 'provides importing methods' do
      expect(DummyImportingModel.respond_to?(:import)).to be(true)
      expect(DummyImportingModel.respond_to?(:__find_in_batches)).to be(true)
    end
  end

  describe '#import' do

    before do
      allow(DummyImportingModel).to receive(:index_name).and_return('foo')
      allow(DummyImportingModel).to receive(:document_type).and_return('foo')
      allow(DummyImportingModel).to receive(:index_exists?).and_return(true)
      allow(DummyImportingModel).to receive(:__batch_to_bulk)
      allow(client).to receive(:bulk).and_return(response)
    end

    let(:client) do
      double('client')
    end

    let(:response) do
      { 'items' => [] }
    end

    context 'when no options are provided' do

      before do
        expect(DummyImportingModel).to receive(:client).and_return(client)
        allow(DummyImportingModel).to receive(:index_exists?).and_return(true)
      end

      it 'uses the client to import documents' do
        expect(DummyImportingModel.import).to eq(0)
      end
    end

    context 'when there is an error' do

      before do
        expect(DummyImportingModel).to receive(:client).and_return(client)
        allow(DummyImportingModel).to receive(:index_exists?).and_return(true)
      end

      let(:response) do
        { 'items' => [{ 'index' => { } }, { 'index' => { 'error' => 'FAILED' } }] }
      end

      it 'returns the number of errors' do
        expect(DummyImportingModel.import).to eq(1)
      end

      context 'when the method is called with the option to return the errors' do

        it 'returns the errors' do
          expect(DummyImportingModel.import(return: 'errors')).to eq([{ 'index' => { 'error' => 'FAILED' } }])
        end
      end

      context 'when the method is called with a block' do

        it 'yields the response to the block' do
          DummyImportingModel.import do |response|
            expect(response['items'].size).to eq(2)
          end
        end
      end
    end

    context 'when the index does not exist' do

      before do
        allow(DummyImportingModel).to receive(:index_exists?).and_return(false)
      end

      it 'raises an exception' do
        expect {
          DummyImportingModel.import
        }.to raise_exception(ArgumentError)
      end
    end

    context 'when the method is called with the force option' do

      before do
        expect(DummyImportingModel).to receive(:create_index!).with(force: true, index: 'foo').and_return(true)
        expect(DummyImportingModel).to receive(:__find_in_batches).with(foo: 'bar').and_return(true)
      end

      it 'deletes and creates the index' do
        expect(DummyImportingModel.import(force: true, foo: 'bar')).to eq(0)
      end
    end

    context 'when the method is called with the refresh option' do

      before do
        expect(DummyImportingModel).to receive(:refresh_index!).with(index: 'foo').and_return(true)
        expect(DummyImportingModel).to receive(:__find_in_batches).with(foo: 'bar').and_return(true)
      end

      it 'refreshes the index' do
        expect(DummyImportingModel.import(refresh: true, foo: 'bar')).to eq(0)
      end
    end

    context 'when a different index name is provided' do

      before do
        expect(DummyImportingModel).to receive(:client).and_return(client)
        expect(client).to receive(:bulk).with(body: nil, index: 'my-new-index', type: 'foo').and_return(response)
      end

      it 'uses the alternate index name' do
        expect(DummyImportingModel.import(index: 'my-new-index')).to eq(0)
      end
    end

    context 'when a different document type is provided' do

      before do
        expect(DummyImportingModel).to receive(:client).and_return(client)
        expect(client).to receive(:bulk).with(body: nil, index: 'foo', type: 'my-new-type').and_return(response)
      end

      it 'uses the alternate index name' do
        expect(DummyImportingModel.import(type: 'my-new-type')).to eq(0)
      end
    end

    context 'the transform method' do

      before do
        expect(DummyImportingModel).to receive(:client).and_return(client)
        expect(DummyImportingModel).to receive(:__transform).and_return(transform)
        expect(DummyImportingModel).to receive(:__batch_to_bulk).with(anything, transform)
      end

      let(:transform) do
        lambda {|a|}
      end

      it 'applies the transform method to the results' do
        expect(DummyImportingModel.import).to eq(0)
      end
    end

    context 'when a transform is provided as an option' do

      context 'when the transform option is not a lambda' do

        let(:transform) do
          'not_callable'
        end

        it 'raises an error' do
          expect {
            DummyImportingModel.import(transform: transform)
          }.to raise_exception(ArgumentError)
        end
      end

      context 'when the transform option is a lambda' do

        before do
          expect(DummyImportingModel).to receive(:client).and_return(client)
          expect(DummyImportingModel).to receive(:__batch_to_bulk).with(anything, transform)
        end

        let(:transform) do
          lambda {|a|}
        end

        it 'applies the transform lambda to the results' do
          expect(DummyImportingModel.import(transform: transform)).to eq(0)
        end
      end
    end
  end
end
