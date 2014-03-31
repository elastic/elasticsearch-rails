require 'test_helper'

class Elasticsearch::Persistence::RepositoryFindTest < Test::Unit::TestCase
  class MyDocument; end

  context "The repository" do
    setup do
      @shoulda_subject = Class.new() { include Elasticsearch::Persistence::Repository::Find }.new

      @client = mock
      @shoulda_subject.stubs(:klass).returns(nil)
      @shoulda_subject.stubs(:index_name).returns('my_index')
      @shoulda_subject.stubs(:client).returns(@client)
    end

    context "find method" do
      should "find one document when passed a single, literal ID" do
        subject.expects(:__find_one).with(1, {})
        subject.find(1)
      end

      should "find multiple documents when passed multiple IDs" do
        subject.expects(:__find_many).with([1, 2], {})
        subject.find(1, 2)
      end

      should "find multiple documents when passed an array of IDs" do
        subject.expects(:__find_many).with([1, 2], {})
        subject.find([1, 2])
      end

      should "pass the options" do
        subject.expects(:__find_one).with(1, { foo: 'bar' })
        subject.find(1, foo: 'bar')

        subject.expects(:__find_many).with([1, 2], { foo: 'bar' })
        subject.find([1, 2], foo: 'bar')

        subject.expects(:__find_many).with([1, 2], { foo: 'bar' })
        subject.find(1, 2, foo: 'bar')
      end
    end

    context "'exists?' method" do
      should "return false when the document does not exist" do
        @client.expects(:exists).returns(false)
        assert_equal false, subject.exists?('1')
      end

      should "return whether document for klass exists" do
        subject.expects(:klass).returns(MyDocument).at_least_once
        subject.expects(:__get_type_from_class).with(MyDocument).returns('my_document')

        @client
          .expects(:exists)
          .with do |arguments|
            assert_equal 'my_document', arguments[:type]
            assert_equal '1', arguments[:id]
          end
          .returns(true)

        assert_equal true, subject.exists?('1')
      end

      should "return whether document exists" do
        subject.expects(:klass).returns(nil)
        subject.expects(:__get_type_from_class).never

        @client
          .expects(:exists)
          .with do |arguments|
            assert_equal '_all', arguments[:type]
            assert_equal '1', arguments[:id]
          end
          .returns(true)

        assert_equal true, subject.exists?('1')
      end

      should "pass options to the client" do
        @client.expects(:exists).with do |arguments|
          assert_equal 'foobarbam', arguments[:index]
          assert_equal 'bambam',    arguments[:routing]
        end

        subject.exists? '1', index: 'foobarbam', routing: 'bambam'
      end
    end

    context "'__find_one' method" do
      should "find document based on klass and return a deserialized object" do
        subject.expects(:klass).returns(MyDocument).at_least_once
        subject.expects(:__get_type_from_class).with(MyDocument).returns('my_document')

        subject.expects(:deserialize).with({'_source' => {'foo' => 'bar'}}).returns(MyDocument.new)

        @client
          .expects(:get)
          .with do |arguments|
            assert_equal 'my_document', arguments[:type]
            assert_equal '1', arguments[:id]
          end
          .returns({'_source' => { 'foo' => 'bar' }})

        assert_instance_of MyDocument, subject.__find_one('1')
      end

      should "find document and return a deserialized object" do
        subject.expects(:klass).returns(nil).at_least_once
        subject.expects(:__get_type_from_class).never

        subject.expects(:deserialize).with({'_source' => {'foo' => 'bar'}}).returns(MyDocument.new)

        @client
          .expects(:get)
          .with do |arguments|
            assert_equal '_all', arguments[:type]
            assert_equal '1', arguments[:id]
          end
          .returns({'_source' => { 'foo' => 'bar' }})

        assert_instance_of MyDocument, subject.__find_one('1')
      end

      should "raise DocumentNotFound exception when the document cannot be found" do
        subject.expects(:klass).returns(nil).at_least_once

        subject.expects(:deserialize).never

        @client
          .expects(:get)
          .raises(Elasticsearch::Transport::Transport::Errors::NotFound)

        assert_raise Elasticsearch::Persistence::Repository::DocumentNotFound do
          subject.__find_one('foobar')
        end
      end

      should "pass other exceptions" do
        subject.expects(:klass).returns(nil).at_least_once

        subject.expects(:deserialize).never

        @client
          .expects(:get)
          .raises(RuntimeError)

        assert_raise RuntimeError do
          subject.__find_one('foobar')
        end
      end

      should "pass options to the client" do
        subject.expects(:klass).returns(nil).at_least_once
        subject.expects(:deserialize)

        @client
          .expects(:get)
          .with do |arguments|
            assert_equal 'foobarbam', arguments[:index]
            assert_equal 'bambam',    arguments[:routing]
          end
          .returns({'_source' => { 'foo' => 'bar' }})

        subject.__find_one '1', index: 'foobarbam', routing: 'bambam'
      end
    end

    context "'__find_many' method" do
      setup do
        @response = {"docs"=>
        [ {"_index"=>"my_index",
           "_type"=>"note",
           "_id"=>"1",
           "_version"=>1,
           "found"=>true,
           "_source"=>{"id"=>"1", "title"=>"Test 1"}},

          {"_index"=>"my_index",
           "_type"=>"note",
           "_id"=>"2",
           "_version"=>1,
           "found"=>true,
           "_source"=>{"id"=>"2", "title"=>"Test 2"}}
        ]}
      end

      should "find documents based on klass and return an Array of deserialized objects" do
        subject.expects(:klass).returns(MyDocument).at_least_once
        subject.expects(:__get_type_from_class).with(MyDocument).returns('my_document')

        subject
          .expects(:deserialize)
          .with(@response['docs'][0])
          .returns(MyDocument.new)

        subject
          .expects(:deserialize)
          .with(@response['docs'][1])
          .returns(MyDocument.new)

        @client
          .expects(:mget)
          .with do |arguments|
            assert_equal 'my_document', arguments[:type]
            assert_equal ['1', '2'], arguments[:body][:ids]
          end
          .returns(@response)

        results = subject.__find_many(['1', '2'])
        assert_instance_of MyDocument, results[0]
        assert_instance_of MyDocument, results[1]
      end

      should "find documents and return an Array of deserialized objects" do
        subject.expects(:klass).returns(nil).at_least_once
        subject.expects(:__get_type_from_class).never

        subject
          .expects(:deserialize)
          .with(@response['docs'][0])
          .returns(MyDocument.new)

        subject
          .expects(:deserialize)
          .with(@response['docs'][1])
          .returns(MyDocument.new)

        @client
          .expects(:mget)
          .with do |arguments|
            assert_equal '_all', arguments[:type]
            assert_equal ['1', '2'], arguments[:body][:ids]
          end
          .returns(@response)

        results = subject.__find_many(['1', '2'])

        assert_equal 2, results.size

        assert_instance_of MyDocument, results[0]
        assert_instance_of MyDocument, results[1]
      end

      should "find keep missing documents in the result as nil" do
        @response = {"docs"=>
        [ {"_index"=>"my_index",
           "_type"=>"note",
           "_id"=>"1",
           "_version"=>1,
           "found"=>true,
           "_source"=>{"id"=>"1", "title"=>"Test 1"}},

          {"_index"=>"my_index",
           "_type"=>"note",
           "_id"=>"3",
           "_version"=>1,
           "found"=>false},

          {"_index"=>"my_index",
           "_type"=>"note",
           "_id"=>"2",
           "_version"=>1,
           "found"=>true,
           "_source"=>{"id"=>"2", "title"=>"Test 2"}}
        ]}

        subject.expects(:klass).returns(MyDocument).at_least_once
        subject.expects(:__get_type_from_class).with(MyDocument).returns('my_document')

        subject
          .expects(:deserialize)
          .with(@response['docs'][0])
          .returns(MyDocument.new)

        subject
          .expects(:deserialize)
          .with(@response['docs'][2])
          .returns(MyDocument.new)

        @client
          .expects(:mget)
          .with do |arguments|
            assert_equal 'my_document', arguments[:type]
            assert_equal ['1', '3', '2'], arguments[:body][:ids]
          end
          .returns(@response)

        results = subject.__find_many(['1', '3', '2'])

        assert_equal 3, results.size

        assert_instance_of MyDocument, results[0]
        assert_instance_of NilClass,   results[1]
        assert_instance_of MyDocument, results[2]
      end

      should "pass options to the client" do
        subject.expects(:klass).returns(nil).at_least_once
        subject.expects(:deserialize).twice

        @client
          .expects(:mget)
          .with do |arguments|
            assert_equal 'foobarbam', arguments[:index]
            assert_equal 'bambam',    arguments[:routing]
          end
          .returns(@response)

        subject.__find_many ['1', '2'], index: 'foobarbam', routing: 'bambam'
      end
    end

  end
end
