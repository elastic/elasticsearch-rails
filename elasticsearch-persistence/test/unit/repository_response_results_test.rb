require 'test_helper'

class Elasticsearch::Persistence::RepositoryResponseResultsTest < Test::Unit::TestCase
  include Elasticsearch::Persistence
  class MyDocument; end

  context "Response results" do
    setup do
      @repository = Repository.new

      @response = { "took" => 2,
                   "timed_out" => false,
                   "_shards" => {"total" => 5, "successful" => 5, "failed" => 0},
                   "hits" =>
                    { "total" => 2,
                      "max_score" => 0.19,
                      "hits" =>
                       [{"_index" => "my_index",
                         "_type" => "note",
                         "_id" => "1",
                         "_score" => 0.19,
                         "_source" => {"id" => 1, "title" => "Test 1"}},

                         {"_index" => "my_index",
                         "_type" => "note",
                         "_id" => "2",
                         "_score" => 0.19,
                         "_source" => {"id" => 2, "title" => "Test 2"}}
                       ]
                    }
                  }

      @shoulda_subject = Repository::Response::Results.new @repository, @response
    end

    should "provide the access to the repository" do
      assert_instance_of Repository::Class, subject.repository
    end

    should "provide the access to the response" do
      assert_equal 5, subject.response['_shards']['total']
    end

    should "wrap the response in Hashie::Mash" do
      assert_equal 5, subject.response._shards.total
    end

    should "return the total" do
      assert_equal 2, subject.total
    end

    should "return the max_score" do
      assert_equal 0.19, subject.max_score
    end

    should "delegate methods to results" do
      subject.repository
        .expects(:deserialize)
        .twice
        .returns(MyDocument.new)

      assert_equal 2, subject.size
      assert_respond_to subject, :each
    end

    should "yield each object with hit" do
      @shoulda_subject = Repository::Response::Results.new \
        @repository,
        { 'hits' => { 'hits' => [{'_id' => '1', 'foo' => 'bar'}] } }

      subject.repository
        .expects(:deserialize)
        .returns('FOO')

      subject.each_with_hit do |object, hit|
        assert_equal 'FOO', object
        assert_equal 'bar', hit.foo
      end
    end

    should "map objects and hits" do
      @shoulda_subject = Repository::Response::Results.new \
        @repository,
        { 'hits' => { 'hits' => [{'_id' => '1', 'foo' => 'bar'}] } }

      subject.repository
        .expects(:deserialize)
        .returns('FOO')

      assert_equal ['FOO---bar'], subject.map_with_hit { |object, hit| "#{object}---#{hit.foo}" }
    end
  end

end
