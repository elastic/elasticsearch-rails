require 'test_helper'

class Elasticsearch::Model::SearchTest < Test::Unit::TestCase
  context "Searching module" do
    class ::DummyProxyModel
      include Elasticsearch::Model::Proxy

      def self.foo
        'classy foo'
      end

      def bar
        'insta barr'
      end

      def as_json(options)
        {foo: 'bar'}
      end
    end

    class ::DummyProxyModelWithCallbacks
      def self.before_save(&block)
        (@callbacks ||= {})[block.hash] = block
      end

      def changes_to_save
        {:foo => ['One', 'Two']}
      end
    end

    should "setup the class proxy method" do
      assert_respond_to DummyProxyModel, :__elasticsearch__
    end

    should "setup the instance proxy method" do
      assert_respond_to DummyProxyModel.new, :__elasticsearch__
    end

    should "register the hook for before_save callback" do
      ::DummyProxyModelWithCallbacks.expects(:before_save).returns(true)
      DummyProxyModelWithCallbacks.__send__ :include, Elasticsearch::Model::Proxy
    end

    should "set the @__changed_model_attributes variable before save" do
      instance = ::DummyProxyModelWithCallbacks.new
      instance.__elasticsearch__.expects(:instance_variable_set).with do |name, value|
        assert_equal :@__changed_model_attributes, name
        assert_equal({foo: 'Two'}, value)
        true
      end

      ::DummyProxyModelWithCallbacks.__send__ :include, Elasticsearch::Model::Proxy

      ::DummyProxyModelWithCallbacks.instance_variable_get(:@callbacks).each do |n,b|
        instance.instance_eval(&b)
      end
    end

    should "delegate methods to the target" do
      assert_respond_to DummyProxyModel.__elasticsearch__,     :foo
      assert_respond_to DummyProxyModel.new.__elasticsearch__, :bar

      assert_raise(NoMethodError) { DummyProxyModel.__elasticsearch__.xoxo }
      assert_raise(NoMethodError) { DummyProxyModel.new.__elasticsearch__.xoxo }

      assert_equal 'classy foo', DummyProxyModel.__elasticsearch__.foo
      assert_equal 'insta barr', DummyProxyModel.new.__elasticsearch__.bar
    end

    should "reset the proxy target for duplicates" do
      model = DummyProxyModel.new
      model_target = model.__elasticsearch__.target
      duplicate = model.dup
      duplicate_target = duplicate.__elasticsearch__.target

      assert_not_equal model, duplicate
      assert_equal model, model_target
      assert_equal duplicate, duplicate_target
    end

    should "return the proxy class from instance proxy" do
      assert_equal Elasticsearch::Model::Proxy::ClassMethodsProxy, DummyProxyModel.new.__elasticsearch__.class.class
    end

    should "return the origin class from instance proxy" do
      assert_equal DummyProxyModel, DummyProxyModel.new.__elasticsearch__.klass
    end

    should "delegate as_json from the proxy to target" do
      assert_equal({foo: 'bar'}, DummyProxyModel.new.__elasticsearch__.as_json)
    end

    should "have inspect method indicating the proxy" do
      assert_match /PROXY/, DummyProxyModel.__elasticsearch__.inspect
      assert_match /PROXY/, DummyProxyModel.new.__elasticsearch__.inspect
    end
  end
end
