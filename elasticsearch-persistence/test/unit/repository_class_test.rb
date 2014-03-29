require 'test_helper'

class Elasticsearch::Persistence::RepositoryClassTest < Test::Unit::TestCase
  context "The default repository class" do

    should "be created from the module" do
      repository = Elasticsearch::Persistence::Repository.new
      assert_instance_of Elasticsearch::Persistence::Repository::Class, repository
    end

    should "store and access the options" do
      repository = Elasticsearch::Persistence::Repository::Class.new foo: 'bar'
      assert_equal 'bar', repository.options[:foo]
    end

    should "instance eval a passed block" do
      $foo = 100
      repository = Elasticsearch::Persistence::Repository::Class.new() { $foo += 1 }
      assert_equal 101, $foo
    end

    should "call a passed block with self" do
      foo = 100
      repository = Elasticsearch::Persistence::Repository::Class.new do |r|
        assert_instance_of Elasticsearch::Persistence::Repository::Class, r
        foo += 1
      end
      assert_equal 101, foo
    end

  end
end
