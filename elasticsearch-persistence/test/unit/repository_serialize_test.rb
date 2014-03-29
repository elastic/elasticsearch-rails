require 'test_helper'

class Elasticsearch::Persistence::RepositorySerializeTest < Test::Unit::TestCase
  context "The repository serialization" do
    class DummyDocument
      def to_hash
        { foo: 'bar' }
      end
    end

    class MyDocument; end

    setup do
      @shoulda_subject = Class.new() { include Elasticsearch::Persistence::Repository::Serialize }.new
    end

    context "serialize" do
      should "call #to_hash on passed object" do
        document = DummyDocument.new
        assert_equal( { foo: 'bar' }, subject.serialize(document))
      end
    end

    context "deserialize" do
      should "get the class name from #klass" do
        subject.expects(:klass)
               .returns(MyDocument)

        MyDocument.expects(:new)

        subject.deserialize( {} )
      end

      should "get the class name from Elasticsearch _type" do
        subject.expects(:klass)
               .returns(nil)

        subject.expects(:__get_klass_from_type)
               .returns(MyDocument)

        MyDocument.expects(:new)

        subject.deserialize( {} )
      end

      should "create the class instance with _source attributes" do
        subject.expects(:klass).returns(nil)

        subject.expects(:__get_klass_from_type).returns(MyDocument)

        MyDocument.expects(:new).with({ 'foo' => 'bar' })

        subject.deserialize( {'_source' => { 'foo' => 'bar' } } )
      end
    end
  end
end
