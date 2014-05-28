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

    should "have the customized inspect method" do
      m = DummyBaseModel.new name: 'Test'
      assert_match /name\: "Test"/, m.inspect
    end
  end
end
