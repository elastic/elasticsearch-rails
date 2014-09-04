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
        assert_equal({foo: 'bar'},  arguments[:body])
        true
      end

      subject.search foo: 'bar'
    end

    should "search in type based on document_type" do
      subject.expects(:document_type).returns('my_special_document').at_least_once
      subject.expects(:__get_type_from_class).never

      @client.expects(:search).with do |arguments|
        assert_equal 'test',                arguments[:index]
        assert_equal 'my_special_document', arguments[:type]
        assert_equal({foo: 'bar'},          arguments[:body])
        true
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
        true
      end

      assert_instance_of Elasticsearch::Persistence::Repository::Response::Results,
                         subject.search(foo: 'bar')
    end

    should "pass options to the client" do
      subject.expects(:klass).returns(nil).at_least_once
      subject.expects(:__get_type_from_class).never

      @client.expects(:search).twice.with do |arguments|
        assert_equal 'bambam', arguments[:routing]
        true
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
        true
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

    should "return the number of domain objects" do
      subject.expects(:search)
        .returns(Elasticsearch::Persistence::Repository::Response::Results.new( subject, {'hits' => { 'total' => 1 }}))
      assert_equal 1, subject.count
    end

    should "pass arguments from count to search" do
      subject.expects(:search)
        .with do |query_or_definition, options|
          assert_equal 'bar', query_or_definition[:query][:match][:foo]
          assert_equal true, options[:ignore_unavailable]
          true
        end
        .returns(Elasticsearch::Persistence::Repository::Response::Results.new( subject, {'hits' => { 'total' => 1 }}))

      subject.count( { query: { match: { foo: 'bar' } } }, { ignore_unavailable: true } )
    end
  end

end
