require 'test_helper'

class Elasticsearch::Model::NamingTest < Test::Unit::TestCase
  context "Naming module" do
    class ::DummyNamingModel
      extend ActiveModel::Naming

      extend  Elasticsearch::Model::Naming::ClassMethods
      include Elasticsearch::Model::Naming::InstanceMethods
    end

    module ::MyNamespace
      class DummyNamingModelInNamespace
        extend ActiveModel::Naming

        extend  Elasticsearch::Model::Naming::ClassMethods
        include Elasticsearch::Model::Naming::InstanceMethods
      end
    end

    should "return the default index_name" do
      assert_equal 'dummy_naming_models', DummyNamingModel.index_name
      assert_equal 'dummy_naming_models', DummyNamingModel.new.index_name
    end

    should "return the sanitized default index_name for namespaced model" do
      assert_equal 'my_namespace-dummy_naming_model_in_namespaces', ::MyNamespace::DummyNamingModelInNamespace.index_name
      assert_equal 'my_namespace-dummy_naming_model_in_namespaces', ::MyNamespace::DummyNamingModelInNamespace.new.index_name
    end

    should "return the default document_type" do
      assert_equal '_doc', DummyNamingModel.document_type
      assert_equal '_doc', DummyNamingModel.new.document_type
    end

    should "set and return the index_name" do
      DummyNamingModel.index_name 'foobar'
      assert_equal 'foobar', DummyNamingModel.index_name

      d = DummyNamingModel.new
      d.index_name 'foobar_d'
      assert_equal 'foobar_d', d.index_name

      modifier = 'r'
      d.index_name Proc.new{ "foobar_#{modifier}" }
      assert_equal 'foobar_r', d.index_name

      modifier = 'z'
      assert_equal 'foobar_z', d.index_name

      modifier = 'f'
      d.index_name { "foobar_#{modifier}" }
      assert_equal 'foobar_f', d.index_name

      modifier = 't'
      assert_equal 'foobar_t', d.index_name
    end

    should "set the index_name with setter" do
      DummyNamingModel.index_name = 'foobar_index_S'
      assert_equal 'foobar_index_S', DummyNamingModel.index_name

      d = DummyNamingModel.new
      d.index_name = 'foobar_index_s'
      assert_equal 'foobar_index_s', d.index_name

      assert_equal 'foobar_index_S', DummyNamingModel.index_name

      modifier2 = 'y'
      DummyNamingModel.index_name = Proc.new{ "foobar_index_#{modifier2}" }
      assert_equal 'foobar_index_y', DummyNamingModel.index_name

      modifier = 'r'
      d.index_name = Proc.new{ "foobar_index_#{modifier}" }
      assert_equal 'foobar_index_r', d.index_name

      modifier = 'z'
      assert_equal 'foobar_index_z', d.index_name

      assert_equal 'foobar_index_y', DummyNamingModel.index_name
    end

    should "set and return the document_type" do
      DummyNamingModel.document_type 'foobar'
      assert_equal 'foobar', DummyNamingModel.document_type

      d = DummyNamingModel.new
      d.document_type 'foobar_d'
      assert_equal 'foobar_d', d.document_type
    end

    should "set the document_type with setter" do
      DummyNamingModel.document_type = 'foobar_type_S'
      assert_equal 'foobar_type_S', DummyNamingModel.document_type

      d = DummyNamingModel.new
      d.document_type = 'foobar_type_s'
      assert_equal 'foobar_type_s', d.document_type

      assert_equal 'foobar_type_S', DummyNamingModel.document_type
    end
  end
end
