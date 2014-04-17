require 'test_helper'

class Elasticsearch::Persistence::RepositorySearchTest < Test::Unit::TestCase
  class MyDocument; end

  context "The repository search" do
    setup do
      @shoulda_subject = Class.new() { include Elasticsearch::Persistence::Repository::Search }.new

      @client = mock
      @shoulda_subject.stubs(:document_type).returns(nil)
      @shoulda_subject.stubs(:klass).returns(nil)
      @shoulda_subject.stubs(:index_name).returns('test')
      @shoulda_subject.stubs(:client).returns(@client)
    end

    should "search in type based on klass" do
      subject.expects(:klass).returns(MyDocument).at_least_once
      subject.expects(:__get_type_from_class).with(MyDocument).returns('my_document')

      @client.expects(:search).with do |arguments|
        assert_equal 'test',        arguments[:index]
        assert_equal 'my_document', arguments[:type]

        assert_equal({foo: 'bar'}, arguments[:body])
      end

      subject.search foo: 'bar'
    end

    should "search in type based on document_type" do
      subject.expects(:document_type).returns('my_special_document').at_least_once
      subject.expects(:__get_type_from_class).never

      @client.expects(:search).with do |arguments|
        assert_equal 'test',                arguments[:index]
        assert_equal 'my_special_document', arguments[:type]

        assert_equal({foo: 'bar'}, arguments[:body])
      end

      subject.search foo: 'bar'
    end

    should "search across all types" do
      subject.expects(:document_type).returns(nil).at_least_once
      subject.expects(:klass).returns(nil).at_least_once
      subject.expects(:__get_type_from_class).never

      @client.expects(:search).with do |arguments|
        assert_equal 'test', arguments[:index]
        assert_equal nil,    arguments[:type]

        assert_equal({foo: 'bar'}, arguments[:body])
      end

      assert_instance_of Elasticsearch::Persistence::Repository::Response::Results,
                         subject.search(foo: 'bar')
    end

    should "pass options to the client" do
      subject.expects(:klass).returns(nil).at_least_once
      subject.expects(:__get_type_from_class).never

      @client.expects(:search).twice.with do |arguments|
        assert_equal 'bambam', arguments[:routing]
      end

      assert_instance_of Elasticsearch::Persistence::Repository::Response::Results,
                         subject.search( {foo: 'bar'}, { routing: 'bambam' } )
      assert_instance_of Elasticsearch::Persistence::Repository::Response::Results,
                         subject.search( 'foobar', { routing: 'bambam' } )
    end

    should "search with simple search" do
      subject.expects(:klass).returns(nil).at_least_once
      subject.expects(:__get_type_from_class).never

      @client.expects(:search).with do |arguments|
        assert_equal 'foobar', arguments[:q]
      end

      assert_instance_of Elasticsearch::Persistence::Repository::Response::Results,
                         subject.search('foobar')
    end

    should "raise error for incorrect search definitions" do
      subject.expects(:klass).returns(nil).at_least_once
      subject.expects(:__get_type_from_class).never

      assert_raise ArgumentError do
        subject.search 123
      end
    end
  end

end
