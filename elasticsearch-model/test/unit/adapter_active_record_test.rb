require 'test_helper'

class Elasticsearch::Model::AdapterActiveRecordTest < Test::Unit::TestCase
  context "Adapter ActiveRecord module: " do
    class ::DummyClassForActiveRecord
      RESPONSE = Struct.new('DummyActiveRecordResponse') do
        def response
          { 'hits' => {'hits' => [ {'_id' => 2}, {'_id' => 1} ]} }
        end
      end.new

      def response
        RESPONSE
      end

      def ids
        [2, 1]
      end
    end

    RESPONSE = { 'hits' => { 'total' => 123, 'max_score' => 456, 'hits' => [] } }

    setup do
      @records = [ stub(id: 1, inspect: '<Model-1>'), stub(id: 2, inspect: '<Model-2>') ]
      @records.stubs(:load).returns(true)
      @records.stubs(:exec_queries).returns(true)
    end

    should "have the register condition" do
      assert_not_nil Elasticsearch::Model::Adapter.adapters[Elasticsearch::Model::Adapter::ActiveRecord]
      assert_equal false, Elasticsearch::Model::Adapter.adapters[Elasticsearch::Model::Adapter::ActiveRecord].call(DummyClassForActiveRecord)
    end

    context "Records" do
      setup do
        DummyClassForActiveRecord.__send__ :include, Elasticsearch::Model::Adapter::ActiveRecord::Records
      end

      should "have the implementation" do
        assert_instance_of Module, Elasticsearch::Model::Adapter::ActiveRecord::Records

        instance = DummyClassForActiveRecord.new
        instance.expects(:klass).returns(mock('class', primary_key: :some_key, where: @records)).at_least_once

        assert_equal @records, instance.records
      end

      should "load the records" do
        instance = DummyClassForActiveRecord.new
        instance.expects(:records).returns(@records)
        instance.load
      end

      should "reorder the records based on hits order" do
        @records.instance_variable_set(:@records, @records)

        instance = DummyClassForActiveRecord.new
        instance.expects(:klass).returns(mock('class', primary_key: :some_key, where: @records)).at_least_once

        assert_equal [1, 2], @records.        to_a.map(&:id)
        assert_equal [2, 1], instance.records.to_a.map(&:id)
      end

      should "not reorder records when SQL order is present" do
        @records.instance_variable_set(:@records, @records)

        instance = DummyClassForActiveRecord.new
        instance.expects(:klass).returns(stub('class', primary_key: :some_key, where: @records)).at_least_once
        instance.records.expects(:order).returns(@records)

        assert_equal [2, 1], instance.records.    to_a.map(&:id)
        assert_equal [1, 2], instance.order(:foo).to_a.map(&:id)
      end
    end

    context "Callbacks" do
      should "register hooks for automatically updating the index" do
        DummyClassForActiveRecord.expects(:after_commit).times(3)

        Elasticsearch::Model::Adapter::ActiveRecord::Callbacks.included(DummyClassForActiveRecord)
      end
    end

    context "Importing" do
      should "implement the __find_in_batches method" do
        DummyClassForActiveRecord.expects(:find_in_batches).returns([])

        DummyClassForActiveRecord.__send__ :extend, Elasticsearch::Model::Adapter::ActiveRecord::Importing
        DummyClassForActiveRecord.__find_in_batches do; end
      end
    end

  end
end
