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
      setup do
        DummyClassForActiveRecord.__send__ :extend, Elasticsearch::Model::Adapter::ActiveRecord::Importing
      end

      should "raise an exception when passing an invalid scope" do
        assert_raise NoMethodError do
          DummyClassForActiveRecord.__find_in_batches(scope: :not_found_method) do; end
        end
      end

      should "implement the __find_in_batches method" do
        DummyClassForActiveRecord.expects(:find_in_batches).returns([])
        DummyClassForActiveRecord.__find_in_batches do; end
      end

      should "limit the relation to a specific scope" do
        DummyClassForActiveRecord.expects(:find_in_batches).returns([])
        DummyClassForActiveRecord.expects(:published).returns(DummyClassForActiveRecord)

        DummyClassForActiveRecord.__find_in_batches(scope: :published) do; end
      end

      should "limit the relation to a specific query" do
        DummyClassForActiveRecord.expects(:find_in_batches).returns([])
        DummyClassForActiveRecord.expects(:where).returns(DummyClassForActiveRecord)

        DummyClassForActiveRecord.__find_in_batches(query: -> { where(color: "red") }) do; end
      end

      should "preprocess the batch if option provided" do
        class << DummyClassForActiveRecord
          # Updates/transforms the batch while fetching it from the database
          # (eg. with information from an external system)
          #
          def update_batch(batch)
            batch.collect { |b| b.to_s + '!' }
          end
        end

        DummyClassForActiveRecord.expects(:__find_in_batches).returns( [:a, :b] )

        DummyClassForActiveRecord.__find_in_batches(preprocess: :update_batch) do |batch|
          assert_same_elements ["a!", "b!"], batch
        end
      end

      context "when transforming models" do
        setup do
          @transform = DummyClassForActiveRecord.__transform
        end

        should "provide an object that responds to #call" do
          assert_respond_to @transform, :call
        end

        should "provide default transformation" do
          model = mock("model", id: 1, __elasticsearch__: stub(as_indexed_json: {}))
          assert_equal @transform.call(model), { index: { _id: 1, data: {} } }
        end
      end
    end
  end
end
