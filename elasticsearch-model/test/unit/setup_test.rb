require 'test_helper'

class Elasticsearch::Model::SetupTest < Test::Unit::TestCase
  context "Setup Module: " do
    class ::DummySetupModel
      extend ActiveModel::Naming
      extend Elasticsearch::Model::Naming::ClassMethods
      extend Elasticsearch::Model::Indexing::ClassMethods
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

    context "settings_file_name" do
      should "default to the document type name" do
        assert_equal "dummy_setup_model", DummySetupModel.settings_file_name
      end
    end

    context "discover_settings_file" do
      context "YAML file exists" do
        should "discover .yml settings file" do
          DummySetupModel.load_path = ['test/support/yml']

          assert_equal "test/support/yml/dummy_setup_model.yml",
              DummySetupModel.discover_settings_file
        end
      end

      context "JSON file exists" do
        should "discover .json settings file" do
          DummySetupModel.load_path = ['test/support/json']

          assert_equal "test/support/json/dummy_setup_model.json",
              DummySetupModel.discover_settings_file
        end
      end
    end

    context "load settings from file" do
      context "YAML" do
        should "load settings and mappings from .yml file" do
          DummySetupModel.load_path = ['test/support/yml']
          DummySetupModel.load_settings_from_file!
          assert_equal({"foo" => "bar"}, DummySetupModel.settings.to_hash)
          assert_equal({"dummy_setup_model"=>{"properties"=>{"baz"=>"qux"}}},
                           DummySetupModel.mappings.to_hash)
        end
      end

      context "JSON" do
        should "load settings and mappings from .yml file" do
          DummySetupModel.load_path = ['test/support/json']
          DummySetupModel.load_settings_from_file!
          assert_equal({"foo" => "bar"}, DummySetupModel.settings.to_hash)
          assert_equal({"dummy_setup_model"=>{"properties"=>{"baz"=>"qux"}}},
                           DummySetupModel.mappings.to_hash)
        end
      end
    end
  end
end

