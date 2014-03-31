require 'test_helper'

class Elasticsearch::Persistence::RepositoryStoreTest < Test::Unit::TestCase
  context "The repository store" do
    class MyDocument; end

    setup do
      @shoulda_subject = Class.new() { include Elasticsearch::Persistence::Repository::Store }.new
      @shoulda_subject.stubs(:index_name).returns('test')
    end

    context "save" do
      should "serialize the document, get type from klass and index it" do
        subject.expects(:serialize).returns({foo: 'bar'})
        subject.expects(:klass).returns('foo_type')
        subject.expects(:__get_id_from_document).returns('1')

        client = mock
        client.expects(:index).with do |arguments|
          assert_equal 'foo_type', arguments[:type]
          assert_equal '1', arguments[:id]
          assert_equal({foo: 'bar'}, arguments[:body])
        end
        subject.expects(:client).returns(client)

        subject.save({foo: 'bar'})
      end

      should "serialize the document, get type from document class and index it" do
        subject.expects(:serialize).returns({foo: 'bar'})
        subject.expects(:klass).returns(nil)
        subject.expects(:__get_type_from_class).with(MyDocument).returns('my_document')
        subject.expects(:__get_id_from_document).returns('1')

        client = mock
        client.expects(:index).with do |arguments|
          assert_equal 'my_document', arguments[:type]
          assert_equal '1', arguments[:id]
          assert_equal({foo: 'bar'}, arguments[:body])
        end
        subject.expects(:client).returns(client)

        subject.save(MyDocument.new)
      end

      should "pass the options to the client" do
        subject.expects(:serialize).returns({foo: 'bar'})
        subject.expects(:klass).returns('foo')
        subject.expects(:__get_id_from_document).returns('1')

        client = mock
        client.expects(:index).with do |arguments|
          assert_equal 'foobarbam', arguments[:index]
          assert_equal 'bambam', arguments[:routing]
        end
        subject.expects(:client).returns(client)

        subject.save({foo: 'bar'}, { index: 'foobarbam', routing: 'bambam' })
      end
    end

    context "delete" do
      should "get type from klass when passed only ID" do
        subject.expects(:serialize).never
        subject.expects(:klass).returns('foo_type')
        subject.expects(:__get_id_from_document).never

        client = mock
        client.expects(:delete).with do |arguments|
          assert_equal 'foo_type', arguments[:type]
          assert_equal '1', arguments[:id]
        end
        subject.expects(:client).returns(client)

        subject.delete('1')
      end

      should "get ID from document and type from klass when passed a document" do
        subject.expects(:serialize).returns({id: '1', foo: 'bar'})
        subject.expects(:klass).returns('foo_type')
        subject.expects(:__get_id_from_document).with({id: '1', foo: 'bar'}).returns('1')

        client = mock
        client.expects(:delete).with do |arguments|
          assert_equal 'foo_type', arguments[:type]
          assert_equal '1', arguments[:id]
        end
        subject.expects(:client).returns(client)

        subject.delete({id: '1', foo: 'bar'})
      end

      should "get ID and type from document when passed a document" do
        subject.expects(:serialize).returns({id: '1', foo: 'bar'})
        subject.expects(:klass).returns(nil)
        subject.expects(:__get_id_from_document).with({id: '1', foo: 'bar'}).returns('1')
        subject.expects(:__get_type_from_class).with(MyDocument).returns('my_document')

        client = mock
        client.expects(:delete).with do |arguments|
          assert_equal 'my_document', arguments[:type]
          assert_equal '1', arguments[:id]
        end
        subject.expects(:client).returns(client)

        subject.delete(MyDocument.new)
      end

      should "pass the options to the client" do
        subject.expects(:klass).returns('foo')

        client = mock
        client.expects(:delete).with do |arguments|
          assert_equal 'foobarbam', arguments[:index]
          assert_equal 'bambam', arguments[:routing]
        end
        subject.expects(:client).returns(client)

        subject.delete('1', index: 'foobarbam', routing: 'bambam')
      end
    end
  end
end
