require 'test_helper'

class Elasticsearch::Persistence::RepositoryClientTest < Test::Unit::TestCase
  context "The repository client" do
    setup do
      @shoulda_subject = Class.new() { include Elasticsearch::Persistence::Repository::Client }.new
    end

    should "have a default client" do
      assert_not_nil     subject.client
      assert_instance_of Elasticsearch::Transport::Client, subject.client
    end

    should "allow to set a client" do
      begin
        subject.client = "Foobar"
        assert_equal "Foobar", subject.client
      ensure
        subject.client = nil
      end
    end

    should "allow to set the client with DSL" do
      begin
        subject.client "Foobar"
        assert_equal "Foobar", subject.client
      ensure
        subject.client = nil
      end
    end
  end
end
