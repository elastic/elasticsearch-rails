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
      m = DummyBaseModel.new id: 1
      assert_equal 1, m.id

      m = DummyBaseModel.new 'id' => 2
      assert_equal 2, m.id
    end

    should "set the ID using setter method" do
      m = DummyBaseModel.new id: 1
      assert_equal 1, m.id

      m.id = 2
      assert_equal 2, m.id
    end

    should "have ID in attributes" do
      m = DummyBaseModel.new id: 1, name: 'Test'
      assert_equal 1, m.attributes[:id]
    end

    should "have the customized inspect method" do
      m = DummyBaseModel.new name: 'Test'
      assert_match /name\: "Test"/, m.inspect
    end
  end
end
