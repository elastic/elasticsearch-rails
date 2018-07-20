require 'test_helper'

class Elasticsearch::Persistence::RepositoryStoreTest < Test::Unit::TestCase
  context "The repository store" do
    class MyDocument; end

    setup do
      @shoulda_subject = Class.new() do
        include Elasticsearch::Persistence::Repository::Store
        include Elasticsearch::Persistence::Repository::Naming
      end.new
      @shoulda_subject.stubs(:index_name).returns('test')
    end

    context "save" do

      should "serialize the document, get type from document_type and index it" do
        subject.expects(:serialize).returns({foo: 'bar'})

        subject.expects(:document_type).returns('my_document')

        subject.expects(:__get_id_from_document).returns('1')

        client = mock
        client.expects(:index).with do |arguments|
          assert_equal 'my_document', arguments[:type]
          assert_equal '1', arguments[:id]
          assert_equal({foo: 'bar'}, arguments[:body])
          true
        end
        subject.expects(:client).returns(client)

        subject.save(MyDocument.new)
      end

      should "pass the options to the client" do
        subject.expects(:serialize).returns({foo: 'bar'})
        subject.expects(:document_type).returns(nil)
        subject.expects(:__get_id_from_document).returns('1')

        client = mock
        client.expects(:index).with do |arguments|
          assert_equal 'my_document', arguments[:type]
          assert_equal 'foobarbam', arguments[:index]
          assert_equal 'bambam', arguments[:routing]
          true
        end
        subject.expects(:client).returns(client)

        subject.save({foo: 'bar'}, { index: 'foobarbam', routing: 'bambam', type: 'my_document' })
      end
    end

    context "update" do
      should "get the ID from first argument and :doc from options" do
        subject.expects(:serialize).never
        subject.expects(:document_type).returns('mydoc')
        subject.expects(:__extract_id_from_document).never

        client = mock
        client.expects(:update).with do |arguments|
          assert_equal '1',     arguments[:id]
          assert_equal 'mydoc', arguments[:type]
          assert_equal({doc: { foo: 'bar' }}, arguments[:body])
          true
        end
        subject.expects(:client).returns(client)

        subject.update('1', doc: { foo: 'bar' })
      end

      should "get the ID from first argument and :script from options" do
        subject.expects(:document_type).returns('mydoc')
        subject.expects(:__extract_id_from_document).never

        client = mock
        client.expects(:update).with do |arguments|
          assert_equal '1',     arguments[:id]
          assert_equal 'mydoc', arguments[:type]
          assert_equal({script: 'ctx._source.foo += 1'}, arguments[:body])
          true
        end
        subject.expects(:client).returns(client)

        subject.update('1', script: 'ctx._source.foo += 1')
      end

      should "get the ID from first argument and :script with :upsert from options" do
        subject.expects(:document_type).returns('mydoc')
        subject.expects(:__extract_id_from_document).never

        client = mock
        client.expects(:update).with do |arguments|
          assert_equal '1',     arguments[:id]
          assert_equal 'mydoc', arguments[:type]
          assert_equal({script: 'ctx._source.foo += 1', upsert: { foo: 1 }}, arguments[:body])
          true
        end
        subject.expects(:client).returns(client)

        subject.update('1', script: 'ctx._source.foo += 1', upsert: { foo: 1 })
      end

      should "get the ID and :doc from document" do
        subject.expects(:document_type).returns('mydoc')

        client = mock
        client.expects(:update).with do |arguments|
          assert_equal '1',     arguments[:id]
          assert_equal 'mydoc', arguments[:type]
          assert_equal({doc: { foo: 'bar' }}, arguments[:body])
          true
        end
        subject.expects(:client).returns(client)

        subject.update(id: '1', foo: 'bar')
      end

      should "get the ID and :script from document" do
        subject.expects(:document_type).returns('mydoc')

        client = mock
        client.expects(:update).with do |arguments|
          assert_equal '1',     arguments[:id]
          assert_equal 'mydoc', arguments[:type]
          assert_equal({script: 'ctx._source.foo += 1'}, arguments[:body])
          true
        end
        subject.expects(:client).returns(client)

        subject.update(id: '1', script: 'ctx._source.foo += 1')
      end

      should "get the ID and :script with :upsert from document" do
        subject.expects(:document_type).returns('mydoc')

        client = mock
        client.expects(:update).with do |arguments|
          assert_equal '1',     arguments[:id]
          assert_equal 'mydoc', arguments[:type]
          assert_equal({script: 'ctx._source.foo += 1', upsert: { foo: 1 } }, arguments[:body])
          true
        end
        subject.expects(:client).returns(client)

        subject.update(id: '1', script: 'ctx._source.foo += 1', upsert: { foo: 1 })
      end

      should "override the type from params" do
        subject.expects(:document_type).never

        client = mock
        client.expects(:update).with do |arguments|
          assert_equal '1',   arguments[:id]
          assert_equal 'foo', arguments[:type]
          assert_equal({script: 'ctx._source.foo += 1'}, arguments[:body])
          true
        end
        subject.expects(:client).returns(client)

        subject.update(id: '1', script: 'ctx._source.foo += 1', type: 'foo')
      end

      should "raise an exception when passed incorrect argument" do
        assert_raise(ArgumentError) { subject.update(MyDocument.new, foo: 'bar') }
      end
    end

    context "delete" do

      should "get ID from document and type from document_type when passed a document" do
        subject.expects(:serialize).returns({id: '1', foo: 'bar'})

        subject.expects(:document_type).returns('my_document')

        subject.expects(:__get_id_from_document).with({id: '1', foo: 'bar'}).returns('1')

        client = mock
        client.expects(:delete).with do |arguments|
          assert_equal 'my_document', arguments[:type]
          assert_equal '1', arguments[:id]
          true
        end
        subject.expects(:client).returns(client)

        subject.delete({id: '1', foo: 'bar'})
      end

      should "get ID and uses the default document type" do
        subject.expects(:serialize).returns({id: '1', foo: 'bar'})
        subject.expects(:document_type).returns('_doc')
        subject.expects(:__get_id_from_document).with({id: '1', foo: 'bar'}).returns('1')

        client = mock
        client.expects(:delete).with do |arguments|
          assert_equal '_doc', arguments[:type]
          assert_equal '1', arguments[:id]
          true
        end
        subject.expects(:client).returns(client)

        subject.delete(MyDocument.new)
      end

      should "pass the options to the client" do
        client = mock
        client.expects(:delete).with do |arguments|
          assert_equal 'my_document', arguments[:type]
          assert_equal 'foobarbam', arguments[:index]
          assert_equal 'bambam', arguments[:routing]
          true
        end
        subject.expects(:client).returns(client)

        subject.delete('1', index: 'foobarbam', routing: 'bambam', type: 'my_document')
      end
    end
  end
end
