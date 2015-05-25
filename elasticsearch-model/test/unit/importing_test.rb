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
      DummyImportingModel.stubs(:index_exists?).returns(true)
      DummyImportingModel.stubs(:__batch_to_bulk)
      assert_equal 0, DummyImportingModel.import
    end

    should "return the number of errors" do
      Elasticsearch::Model::Adapter.expects(:from_class)
                                   .with(DummyImportingModel)
                                   .returns(DummyImportingAdapter)

      DummyImportingModel.__send__ :include, Elasticsearch::Model::Importing

      client = mock('client')
      client.expects(:bulk).returns({'items' => [ {'index' => {}}, {'index' => {'error' => 'FAILED'}} ]})

      DummyImportingModel.stubs(:client).returns(client)
      DummyImportingModel.stubs(:index_name).returns('foo')
      DummyImportingModel.stubs(:document_type).returns('foo')
      DummyImportingModel.stubs(:index_exists?).returns(true)
      DummyImportingModel.stubs(:__batch_to_bulk)

      assert_equal 1, DummyImportingModel.import
    end

    should "return an array of error elements" do
      Elasticsearch::Model::Adapter.expects(:from_class)
                                   .with(DummyImportingModel)
                                   .returns(DummyImportingAdapter)

      DummyImportingModel.__send__ :include, Elasticsearch::Model::Importing

      client = mock('client')
      client.expects(:bulk).returns({'items' => [ {'index' => {}}, {'index' => {'error' => 'FAILED'}} ]})

      DummyImportingModel.stubs(:client).returns(client)
      DummyImportingModel.stubs(:index_name).returns('foo')
      DummyImportingModel.stubs(:document_type).returns('foo')
      DummyImportingModel.stubs(:index_exists?).returns(true)
      DummyImportingModel.stubs(:__batch_to_bulk)

      assert_equal [{'index' => {'error' => 'FAILED'}}], DummyImportingModel.import(return: 'errors')
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
      DummyImportingModel.stubs(:index_exists?).returns(true)
      DummyImportingModel.stubs(:__batch_to_bulk)

      DummyImportingModel.import do |response|
        assert_equal 2, response['items'].size
      end
    end

    context "when the index does not exist" do
      should "raise" do
        Elasticsearch::Model::Adapter.expects(:from_class)
                                     .with(DummyImportingModel)
                                     .returns(DummyImportingAdapter)

        DummyImportingModel.__send__ :include, Elasticsearch::Model::Importing

        DummyImportingModel.expects(:index_name).returns('foo')
        DummyImportingModel.expects(:document_type).returns('foo')
        DummyImportingModel.expects(:index_exists?).returns(false)
        assert_raise ArgumentError do
          DummyImportingModel.import
        end
      end
    end

    context "with the force option" do
      should "delete and create the index" do
        DummyImportingModel.expects(:__find_in_batches).with do |options|
          assert_equal 'bar', options[:foo]
          assert_nil   options[:force]
          true
        end

        DummyImportingModel.expects(:create_index!).with do |options|
          assert_equal true, options[:force]
          true
        end

        DummyImportingModel.expects(:index_name).returns('foo')
        DummyImportingModel.expects(:document_type).returns('foo')

        DummyImportingModel.import force: true, foo: 'bar'
      end
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
      DummyImportingModel.stubs(:index_exists?).returns(true)
      DummyImportingModel.stubs(:__batch_to_bulk)

      DummyImportingModel.import index: 'my-new-index', type: 'my-other-type'
    end

    should "use the default transform from adapter" do
      client = mock('client', bulk: {'items' => []})
      transform = lambda {|a|}

      DummyImportingModel.stubs(:client).returns(client)
      DummyImportingModel.stubs(:index_exists?).returns(true)
      DummyImportingModel.expects(:__transform).returns(transform)
      DummyImportingModel.expects(:__batch_to_bulk).with(anything, transform)

      DummyImportingModel.import index: 'foo', type: 'bar'
    end

    should "use the transformer from options" do
      client = mock('client', bulk: {'items' => []})
      transform = lambda {|a|}

      DummyImportingModel.stubs(:client).returns(client)
      DummyImportingModel.stubs(:index_exists?).returns(true)
      DummyImportingModel.expects(:__batch_to_bulk).with(anything, transform)

      DummyImportingModel.import index: 'foo', type: 'bar', transform: transform
    end

    should "raise an ArgumentError if transform doesn't respond to the call method" do
      assert_raise ArgumentError do
        DummyImportingModel.import index: 'foo', type: 'bar', transform: "not_callable"
      end
    end
  end
end
