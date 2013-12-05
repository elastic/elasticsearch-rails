require 'test_helper'

class Elasticsearch::Model::SerializingTest < Test::Unit::TestCase
  context "Serializing module" do
    class DummyClass
      include Elasticsearch::Model::Serializing::InstanceMethods

      def as_json(options={})
        'HASH'
      end
    end

    should "delegate to as_json by default" do
      assert_equal 'HASH', DummyClass.new.as_indexed_json
    end
  end
end
