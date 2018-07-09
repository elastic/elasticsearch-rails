require "test_helper"

class Elasticsearch::Model::NamingInheritanceTest < Test::Unit::TestCase
  def setup
    Elasticsearch::Model.settings[:inheritance_enabled] = true
  end

  def teardown
    Elasticsearch::Model.settings[:inheritance_enabled] = false
  end

  context "Naming module with inheritance" do
    class ::TestBase
      extend ActiveModel::Naming

      extend  Elasticsearch::Model::Naming::ClassMethods
      include Elasticsearch::Model::Naming::InstanceMethods
    end

    class ::Animal < ::TestBase
      extend ActiveModel::Naming

      extend  Elasticsearch::Model::Naming::ClassMethods
      include Elasticsearch::Model::Naming::InstanceMethods

      index_name "mammals"
      document_type "mammal"
    end

    class ::Dog < ::Animal
    end

    module ::MyNamespace
      class Dog < ::Animal
      end
    end

    class ::Cat < ::Animal
      extend ActiveModel::Naming

      extend  Elasticsearch::Model::Naming::ClassMethods
      include Elasticsearch::Model::Naming::InstanceMethods

      index_name "cats"
      document_type "cat"
    end

    should "return the default index_name" do
      assert_equal "test_bases", TestBase.index_name
      assert_equal "test_bases", TestBase.new.index_name
    end

    should "return the explicit index_name" do
      assert_equal "mammals", Animal.index_name
      assert_equal "mammals", Animal.new.index_name

      assert_equal "cats", Cat.index_name
      assert_equal "cats", Cat.new.index_name
    end

    should "return the ancestor index_name" do
      assert_equal "mammals", Dog.index_name
      assert_equal "mammals", Dog.new.index_name
    end

    should "return the ancestor index_name for namespaced model" do
      assert_equal "mammals", ::MyNamespace::Dog.index_name
      assert_equal "mammals", ::MyNamespace::Dog.new.index_name
    end

    should "return the default document_type" do
      assert_equal "test_base", TestBase.document_type
      assert_equal "test_base", TestBase.new.document_type
    end

    should "return the explicit document_type" do
      assert_equal "mammal", Animal.document_type
      assert_equal "mammal", Animal.new.document_type

      assert_equal "cat", Cat.document_type
      assert_equal "cat", Cat.new.document_type
    end

    should "return the ancestor document_type" do
      assert_equal "mammal", Dog.document_type
      assert_equal "mammal", Dog.new.document_type
    end

    should "return the ancestor document_type for namespaced model" do
      assert_equal "mammal", ::MyNamespace::Dog.document_type
      assert_equal "mammal", ::MyNamespace::Dog.new.document_type
    end
  end
end
