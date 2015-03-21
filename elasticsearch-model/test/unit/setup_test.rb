require 'test_helper'

class Elasticsearch::Model::SetupTest < Test::Unit::TestCase
  context "Setup Module: " do
    class ::DummySetupModel
      extend ActiveModel::Naming
      extend Elasticsearch::Model::Setup::ClassMethods
    end

    context "load_path" do
      should "sets the load path for the discovery of settings files" do
        DummySetupModel.load_path = ["test/support"]
        assert_equal ["test/support"], DummySetupModel.load_path
      end

      should "use config/elasticsearch as default" do
        DummySetupModel.load_path = nil
        assert_equal ["config/elasticsearch"], DummySetupModel.load_path
      end
    end
  end
end

