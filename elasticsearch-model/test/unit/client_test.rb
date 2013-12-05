require 'test_helper'

class Elasticsearch::Model::ClientTest < Test::Unit::TestCase
  context "Client module" do
    class ::DummyClientModel
      extend  Elasticsearch::Model::Client::ClassMethods
      include Elasticsearch::Model::Client::InstanceMethods
    end

    should "have the default client method" do
      assert_instance_of Elasticsearch::Transport::Client, DummyClientModel.client
      assert_instance_of Elasticsearch::Transport::Client, DummyClientModel.new.client
    end

    should "set the client for the model" do
      DummyClientModel.client = 'foobar'
      assert_equal 'foobar', DummyClientModel.client
      assert_equal 'foobar', DummyClientModel.new.client
    end

    should "set the client for a model instance" do
      instance = DummyClientModel.new
      instance.client = 'moobam'
      assert_equal 'moobam', instance.client
    end
  end
end
