require 'test_helper'

class Elasticsearch::Persistence::RepositoryStoreTest < Test::Unit::TestCase
  context "The repository store" do
    class MyDocument; end
    class AnotherDocument; end

    setup do
      @shoulda_subject = Class.new() do
        include Elasticsearch::Persistence::Repository::Store
        include Elasticsearch::Persistence::Repository::Naming
      end.new
      @shoulda_subject.stubs(:index_name).returns('test')
    end

    context "save" do
      should "serialize the document, get type from klass and index it" do
        subject.expects(:serialize).returns({foo: 'bar'})
        subject.expects(:document_type).returns(nil)
        subject.expects(:klass).at_least_once.returns(MyDocument)
        subject.expects(:__get_type_from_class).with(MyDocument).at_least_once.returns('my_document')
        subject.expects(:__get_id_from_document).returns('1')

        client = mock
        client.expects(:index).with do |arguments|
          assert_equal 'my_document', arguments[:type]
          assert_equal '1', arguments[:id]
          assert_equal({foo: 'bar'}, arguments[:body])
          true
        end
        subject.expects(:client).returns(client)

        subject.save({foo: 'bar'})
      end

      should "serialize the document, get type from document class and index it" do
        subject.expects(:serialize).returns({foo: 'bar'})
        subject.expects(:document_type).returns(nil)
        subject.expects(:klass).at_least_once.returns(nil)
        subject.expects(:__get_type_from_class).with(MyDocument).returns('my_document')
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

      should "serialize the document, get type from document_type and index it" do
        subject.expects(:serialize).returns({foo: 'bar'})

        subject.expects(:document_type).returns('my_document')

        subject.expects(:klass).never
        subject.expects(:__get_type_from_class).never

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
        subject.expects(:klass).at_least_once.returns(MyDocument)
        subject.expects(:__get_type_from_class).with(MyDocument).returns('my_document')
        subject.expects(:__get_id_from_document).returns('1')

        client = mock
        client.expects(:index).with do |arguments|
          assert_equal 'foobarbam', arguments[:index]
          assert_equal 'bambam', arguments[:routing]
          true
        end
        subject.expects(:client).returns(client)

        subject.save({foo: 'bar'}, { index: 'foobarbam', routing: 'bambam' })
      end
    end

    context "bulk save" do
      setup do
        @documents = [
          { foo: 'bar' },
          { bar: 'baz' }
        ]
      end

      should "serialize the documents, get type from klass and index them" do
        subject.expects(:serialize).twice.returns(@documents[0]).then.returns(@documents[1])
        subject.expects(:document_type).twice.returns(nil)
        subject.expects(:klass).at_least_once.returns(MyDocument)
        subject.expects(:__get_type_from_class).twice.with(MyDocument).returns('my_document')
        subject.expects(:__get_id_from_document).twice.returns('1').then.returns('2')

        client = mock
        client.expects(:bulk).with do |arguments|
          body = arguments[:body]

          assert_equal 'my_document', body[0][:index][:_type]
          assert_equal '1', body[0][:index][:_id]
          assert_equal({foo: 'bar'}, body[0][:index][:data])
          assert_equal 'my_document', body[1][:index][:_type]
          assert_equal '2', body[1][:index][:_id]
          assert_equal({bar: 'baz'}, body[1][:index][:data])
          true
        end
        subject.expects(:client).returns(client)

        subject.save(@documents)
      end

      should "serialize the documents with different class, get types from klass and index them" do
        subject.expects(:serialize).twice.returns(@documents[0]).then.returns(@documents[1])
        subject.expects(:document_type).twice.returns(nil)
        subject.expects(:klass).twice.returns(MyDocument).then.returns(AnotherDocument)
        subject.expects(:__get_type_from_class).twice.returns('my_document').then.returns('another_document')
        subject.expects(:__get_id_from_document).twice.returns('1').then.returns('2')

        client = mock
        client.expects(:bulk).with do |arguments|
          body = arguments[:body]

          assert_equal 'my_document', body[0][:index][:_type]
          assert_equal 'another_document', body[1][:index][:_type]
          true
        end
        subject.expects(:client).returns(client)

        subject.save(@documents)
      end

      should "serialize documents, get types from document classes and index them" do
        subject.expects(:serialize).twice.returns(@documents[0]).then.returns(@documents[1])
        subject.expects(:document_type).twice.returns(nil)
        subject.expects(:klass).at_least_once.returns(nil)
        subject.expects(:__get_type_from_class).with(MyDocument).returns('my_document')
        subject.expects(:__get_type_from_class).with(AnotherDocument).returns('another_document')
        subject.expects(:__get_id_from_document).twice.returns('1').then.returns('2')

        client = mock
        client.expects(:bulk).with do |arguments|
          body = arguments[:body]

          assert_equal 'my_document', body[0][:index][:_type]
          assert_equal 'another_document', body[1][:index][:_type]
          true
        end
        subject.expects(:client).returns(client)

        subject.save([MyDocument.new, AnotherDocument.new])
      end

      should "serialize documents, get types from document_type and index them" do
        subject.expects(:serialize).twice.returns(@documents[0]).then.returns(@documents[1])
        subject.expects(:document_type).twice.returns('my_document')
        subject.expects(:klass).never
        subject.expects(:__get_type_from_class).never
        subject.expects(:__get_id_from_document).twice.returns('1').then.returns('2')

        client = mock
        client.expects(:bulk).with do |arguments|
          body = arguments[:body]

          assert_equal 'my_document', body[0][:index][:_type]
          assert_equal 'my_document', body[1][:index][:_type]
          true
        end
        subject.expects(:client).returns(client)

        subject.save([MyDocument.new, AnotherDocument.new])
      end

      should "pass the options to the each bulk action" do
        subject.expects(:serialize).twice.returns(@documents[0]).then.returns(@documents[1])
        subject.expects(:document_type).twice.returns(nil)
        subject.expects(:klass).at_least_once.returns(MyDocument)
        subject.expects(:__get_type_from_class).twice.with(MyDocument).returns('my_document')
        subject.expects(:__get_id_from_document).twice.returns('1').then.returns('2')

        client = mock
        client.expects(:bulk).with do |arguments|
          body = arguments[:body]

          assert_equal 'foo', body[0][:index][:_index]
          assert_equal 'foo', body[1][:index][:_index]
          true
        end
        subject.expects(:client).returns(client)

        subject.save(@documents, { _index: 'foo' })
      end

      should "extract the options like _parent, _version, _routing from document" do
        @documents = [
          { foo: :bar, _routing: 'parent-key', _parent: 'parent-key', _version: 5 },
          { foo: :baz, _version: 1 }
        ]

        subject.expects(:serialize).twice.returns(@documents[0]).then.returns(@documents[1])
        subject.expects(:document_type).twice.returns(nil)
        subject.expects(:klass).at_least_once.returns(MyDocument)
        subject.expects(:__get_type_from_class).twice.with(MyDocument).returns('my_document')
        subject.expects(:__get_id_from_document).twice.returns('1').then.returns('2')

        client = mock
        client.expects(:bulk).with do |arguments|
          body = arguments[:body]

          assert_equal '1',          body[0][:index][:_id]
          assert_equal 'parent-key', body[0][:index][:_parent]
          assert_equal 'parent-key', body[0][:index][:_routing]
          assert_equal 5,            body[0][:index][:_version]
          assert_equal [:foo],       body[0][:index][:data].keys

          assert_equal '2',    body[1][:index][:_id]
          assert_equal 1,      body[1][:index][:_version]
          assert_equal [:foo], body[1][:index][:data].keys
          true
        end

        subject.expects(:client).returns(client)

        subject.save(@documents)
      end

      should "not modify passed documents (in case of Hash as document) when extracting attributes" do
        @documents = [
          { foo: :bar, _parent: 'parent-key' },
          { foo: :baz, _version: 5 }
        ]

        subject.instance_eval do
          def serialize(document) ; return document.to_hash ; end
          def klass               ; return MyDocument       ; end
          def document_type       ; return nil              ; end
        end

        client = mock
        client.expects(:bulk)
        subject.expects(:client).returns(client)

        subject.save(@documents)
        assert_equal 'parent-key', @documents[0][:_parent]
        assert_equal 5,            @documents[1][:_version]
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
      should "get type from klass when passed only ID" do
        subject.expects(:serialize).never
        subject.expects(:document_type).returns(nil)
        subject.expects(:klass).at_least_once.returns(MyDocument)
        subject.expects(:__get_type_from_class).with(MyDocument).returns('my_document')
        subject.expects(:__get_id_from_document).never

        client = mock
        client.expects(:delete).with do |arguments|
          assert_equal 'my_document', arguments[:type]
          assert_equal '1', arguments[:id]
          true
        end
        subject.expects(:client).returns(client)

        subject.delete('1')
      end

      should "get ID from document and type from klass when passed a document" do
        subject.expects(:serialize).returns({id: '1', foo: 'bar'})
        subject.expects(:document_type).returns(nil)
        subject.expects(:klass).at_least_once.returns(MyDocument)
        subject.expects(:__get_type_from_class).with(MyDocument).returns('my_document')
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

      should "get ID from document and type from document_type when passed a document" do
        subject.expects(:serialize).returns({id: '1', foo: 'bar'})

        subject.expects(:document_type).returns('my_document')

        subject.expects(:klass).never
        subject.expects(:__get_type_from_class).never

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

      should "get ID and type from document when passed a document" do
        subject.expects(:serialize).returns({id: '1', foo: 'bar'})
        subject.expects(:document_type).returns(nil)
        subject.expects(:klass).at_least_once.returns(nil)
        subject.expects(:__get_type_from_class).with(MyDocument).returns('my_document')
        subject.expects(:__get_id_from_document).with({id: '1', foo: 'bar'}).returns('1')

        client = mock
        client.expects(:delete).with do |arguments|
          assert_equal 'my_document', arguments[:type]
          assert_equal '1', arguments[:id]
          true
        end
        subject.expects(:client).returns(client)

        subject.delete(MyDocument.new)
      end

      should "pass the options to the client" do
        subject.expects(:document_type).returns(nil)
        subject.expects(:klass).at_least_once.returns(MyDocument)
        subject.expects(:__get_type_from_class).returns('my_document')

        client = mock
        client.expects(:delete).with do |arguments|
          assert_equal 'foobarbam', arguments[:index]
          assert_equal 'bambam', arguments[:routing]
          true
        end
        subject.expects(:client).returns(client)

        subject.delete('1', index: 'foobarbam', routing: 'bambam')
      end
    end
  end
end
