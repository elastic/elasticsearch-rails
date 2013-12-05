require 'test_helper'

class Elasticsearch::Model::ImportingTest < Test::Unit::TestCase
  context "Importing module" do
    class ::DummyImportingModel
    end

    module ::DummyImportingAdapter
      module ImportingMixin
        def __find_in_batches(options={}, &block)
          yield if block_given?
        end
      end

      def importing_mixin
        ImportingMixin
      end; module_function :importing_mixin
    end

    should "include methods from the module and adapter" do
      Elasticsearch::Model::Adapter.expects(:from_class)
                                   .with(DummyImportingModel)
                                   .returns(DummyImportingAdapter)

      DummyImportingModel.__send__ :include, Elasticsearch::Model::Importing

      assert_respond_to DummyImportingModel, :import
      assert_respond_to DummyImportingModel, :__find_in_batches
    end

    should "call the client when importing" do
      Elasticsearch::Model::Adapter.expects(:from_class)
                                   .with(DummyImportingModel)
                                   .returns(DummyImportingAdapter)

      DummyImportingModel.__send__ :include, Elasticsearch::Model::Importing

      client = mock('client')
      client.expects(:bulk).returns({'items' => []})

      DummyImportingModel.expects(:client).returns(client)
      DummyImportingModel.expects(:index_name).returns('foo')
      DummyImportingModel.expects(:document_type).returns('foo')

      assert_equal 0, DummyImportingModel.import
    end

    should "return number of errors" do
      Elasticsearch::Model::Adapter.expects(:from_class)
                                   .with(DummyImportingModel)
                                   .returns(DummyImportingAdapter)

      DummyImportingModel.__send__ :include, Elasticsearch::Model::Importing

      client = mock('client')
      client.expects(:bulk).returns({'items' => [ {'index' => {}}, {'index' => {'error' => 'FAILED'}} ]})

      DummyImportingModel.stubs(:client).returns(client)
      DummyImportingModel.stubs(:index_name).returns('foo')
      DummyImportingModel.stubs(:document_type).returns('foo')

      assert_equal 1, DummyImportingModel.import
    end

    should "yield the response" do
      Elasticsearch::Model::Adapter.expects(:from_class)
                                   .with(DummyImportingModel)
                                   .returns(DummyImportingAdapter)

      DummyImportingModel.__send__ :include, Elasticsearch::Model::Importing

      client = mock('client')
      client.expects(:bulk).returns({'items' => [ {'index' => {}}, {'index' => {'error' => 'FAILED'}} ]})

      DummyImportingModel.stubs(:client).returns(client)
      DummyImportingModel.stubs(:index_name).returns('foo')
      DummyImportingModel.stubs(:document_type).returns('foo')

      DummyImportingModel.import do |response|
        assert_equal 2, response['items'].size
      end
    end
  end
end
