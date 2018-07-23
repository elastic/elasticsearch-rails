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
               .returns(MyDocument).twice

        MyDocument.expects(:new)

        subject.deserialize( {} )
      end

      should "raise an error when klass isn't set" do
        subject.expects(:klass).returns(nil)

        assert_raise(NameError) { subject.deserialize( {} ) }
      end
    end
  end
end
