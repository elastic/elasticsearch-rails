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
        def __transform
          lambda {|a|}
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
      DummyImportingModel.stubs(:__batch_to_bulk)
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
      DummyImportingModel.stubs(:__batch_to_bulk)

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
      DummyImportingModel.stubs(:__batch_to_bulk)

      DummyImportingModel.import do |response|
        assert_equal 2, response['items'].size
      end
    end

    should "delete and create the index with the force option" do
      DummyImportingModel.expects(:__find_in_batches).with do |options|
        assert_equal 'bar', options[:foo]
        assert_nil   options[:force]
      end

      DummyImportingModel.expects(:create_index!).with do |options|
        assert_equal true, options[:force]
      end

      DummyImportingModel.expects(:index_name).returns('foo')
      DummyImportingModel.expects(:document_type).returns('foo')

      DummyImportingModel.import force: true, foo: 'bar'
    end

    should "allow passing a different index / type" do
      Elasticsearch::Model::Adapter.expects(:from_class)
                                   .with(DummyImportingModel)
                                   .returns(DummyImportingAdapter)

      DummyImportingModel.__send__ :include, Elasticsearch::Model::Importing

      client = mock('client')

      client
        .expects(:bulk)
          .with do |options|
            assert_equal 'my-new-index',  options[:index]
            assert_equal 'my-other-type', options[:type]
            true
          end
        .returns({'items' => [ {'index' => {} }]})

      DummyImportingModel.stubs(:client).returns(client)
      DummyImportingModel.stubs(:__batch_to_bulk)

      DummyImportingModel.import index: 'my-new-index', type: 'my-other-type'
    end

    should "default to the adapter's bulk transform" do
      client = mock('client', bulk: {'items' => []})
      transform = lambda {|a|}

      DummyImportingModel.stubs(:client).returns(client)
      DummyImportingModel.expects(:__transform).returns(transform)
      DummyImportingModel.expects(:__batch_to_bulk).with(anything, transform)

      DummyImportingModel.import index: 'foo', type: 'bar'
    end

    should "use the optioned transform" do
      client = mock('client', bulk: {'items' => []})
      transform = lambda {|a|}

      DummyImportingModel.stubs(:client).returns(client)
      DummyImportingModel.expects(:__batch_to_bulk).with(anything, transform)

      DummyImportingModel.import index: 'foo', type: 'bar', transform: transform
    end

    should "raise an ArgumentError if transform is an object that doesn't respond to #call" do
      assert_raise ArgumentError do
        DummyImportingModel.import index: 'foo', type: 'bar', transform: "not_callable"
      end
    end
  end
end
