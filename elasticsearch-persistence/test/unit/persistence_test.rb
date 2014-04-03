require 'test_helper'

class Elasticsearch::Persistence::ModuleTest < Test::Unit::TestCase
  context "The Persistence module" do

    context "client" do
      should "have a default client" do
        client = Elasticsearch::Persistence.client
        assert_not_nil     client
        assert_instance_of Elasticsearch::Transport::Client, client
      end

      should "allow to set a client" do
        begin
          Elasticsearch::Persistence.client = "Foobar"
          assert_equal "Foobar", Elasticsearch::Persistence.client
        ensure
          Elasticsearch::Persistence.client = nil
        end
      end

      should "allow to set a client with DSL" do
        begin
          Elasticsearch::Persistence.client "Foobar"
          assert_equal "Foobar", Elasticsearch::Persistence.client
        ensure
          Elasticsearch::Persistence.client = nil
        end
      end
    end
  end
end
