require 'test_helper'

require 'elasticsearch/persistence/model'
require 'elasticsearch/persistence/model/rails'

class Elasticsearch::Persistence::ModelBaseTest < Test::Unit::TestCase
  context "The model" do
    setup do
      class DummyBaseModel
        include Elasticsearch::Persistence::Model

        attribute :name, String
      end
    end

    should "respond to id, _id, _index, _type and _version" do
      model = DummyBaseModel.new

      [:id, :_id, :_index, :_type, :_version].each { |method| assert_respond_to model, method }
    end

    should "set the ID from attributes during initialization" do
      model = DummyBaseModel.new id: 1
      assert_equal 1, model.id

      model = DummyBaseModel.new 'id' => 2
      assert_equal 2, model.id
    end

    should "set the ID using setter method" do
      model = DummyBaseModel.new id: 1
      assert_equal 1, model.id

      model.id = 2
      assert_equal 2, model.id
    end

    should "have ID in attributes" do
      model = DummyBaseModel.new id: 1, name: 'Test'
      assert_equal 1, model.attributes[:id]
    end

    should "have the customized inspect method" do
      model = DummyBaseModel.new name: 'Test'
      assert_match /name\: "Test"/, model.inspect
    end

    context "with custom document_type" do
      setup do
        @model = DummyBaseModel
        @gateway = mock()
        @mapping = mock()
        @model.stubs(:gateway).returns(@gateway)
        @gateway.stubs(:mapping).returns(@mapping)
        @document_type = 'dummybase'
      end

      should "forward the argument to mapping" do
        @gateway.expects(:document_type).with(@document_type).once
        @mapping.expects(:type=).with(@document_type).once
        @model.document_type @document_type
      end

      should "return the value from the gateway" do
        @gateway.expects(:document_type).once.returns(@document_type)
        @mapping.expects(:type=).never
        returned_type = @model.document_type
        assert_equal @document_type, returned_type
      end
    end
  end
end
