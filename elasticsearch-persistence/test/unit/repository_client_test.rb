require 'test_helper'

class Elasticsearch::Persistence::RepositoryClientTest < Test::Unit::TestCase
  context "A repository client" do
    class DummyReposistory
      include Elasticsearch::Persistence::Repository
    end

    setup do
      @shoulda_subject = DummyReposistory.new
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
  end
end
