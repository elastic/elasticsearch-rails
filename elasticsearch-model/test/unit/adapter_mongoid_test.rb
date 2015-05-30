require 'test_helper'

class Elasticsearch::Model::AdapterMongoidTest < Test::Unit::TestCase
  context "Adapter Mongoid module: " do
    class ::DummyClassForMongoid
      RESPONSE = Struct.new('DummyMongoidResponse') do
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

    setup do
      @records = [ stub(id: 1, inspect: '<Model-1>'), stub(id: 2, inspect: '<Model-2>') ]
      ::Symbol.any_instance.stubs(:in).returns(@records)
    end

    should "have the register condition" do
      assert_not_nil Elasticsearch::Model::Adapter.adapters[Elasticsearch::Model::Adapter::Mongoid]
      assert_equal false, Elasticsearch::Model::Adapter.adapters[Elasticsearch::Model::Adapter::Mongoid].call(DummyClassForMongoid)
    end

    context "Records" do
      setup do
        DummyClassForMongoid.__send__ :include, Elasticsearch::Model::Adapter::Mongoid::Records
      end

      should "have the implementation" do
        assert_instance_of Module, Elasticsearch::Model::Adapter::Mongoid::Records

        instance = DummyClassForMongoid.new
        instance.expects(:klass).returns(mock('class', where: @records))

        assert_equal @records, instance.records
      end

      should "reorder the records based on hits order" do
        @records.instance_variable_set(:@records, @records)

        instance = DummyClassForMongoid.new
        instance.expects(:klass).returns(mock('class', where: @records))

        assert_equal [1, 2], @records.        to_a.map(&:id)
        assert_equal [2, 1], instance.records.to_a.map(&:id)
      end

      should "not reorder records when SQL order is present" do
        @records.instance_variable_set(:@records, @records)

        instance = DummyClassForMongoid.new
        instance.expects(:klass).returns(stub('class', where: @records)).at_least_once
        instance.records.expects(:asc).returns(@records)

        assert_equal [2, 1], instance.records.to_a.map(&:id)
        assert_equal [1, 2], instance.asc.to_a.map(&:id)
      end
    end

    context "Callbacks" do
      should "register hooks for automatically updating the index" do
        DummyClassForMongoid.expects(:after_create)
        DummyClassForMongoid.expects(:after_update)
        DummyClassForMongoid.expects(:after_destroy)

        Elasticsearch::Model::Adapter::Mongoid::Callbacks.included(DummyClassForMongoid)
      end
    end

    context "Importing" do
      setup do
        DummyClassForMongoid.__send__ :extend, Elasticsearch::Model::Adapter::Mongoid::Importing
      end

      should "raise an exception when passing an invalid scope" do
        assert_raise NoMethodError do
          DummyClassForMongoid.__find_in_batches(scope: :not_found_method) do; end
        end
      end

      should "implement the __find_in_batches method" do
        DummyClassForMongoid.expects(:batch_size).returns(stub(no_timeout: []))
        DummyClassForMongoid.__find_in_batches do; end
      end

      should "limit the relation to a specific scope" do
        DummyClassForMongoid.expects(:batch_size).returns(stub(no_timeout: []))
        DummyClassForMongoid.expects(:published).returns(DummyClassForMongoid)

        DummyClassForMongoid.__find_in_batches(scope: :published) do; end
      end

      should "limit the relation to a specific query" do
        DummyClassForMongoid.expects(:where).returns(stub(batch_size: stub(no_timeout: [])))

        DummyClassForMongoid.__find_in_batches(query: -> { where(color: "red") }) do; end
      end

      should "preprocess the batch if option provided" do
        class << DummyClassForMongoid
          # Updates/transforms the batch while fetching it from the database
          # (eg. with information from an external system)
          #
          def update_batch(batch)
            batch.collect { |b| b.to_s + '!' }
          end
        end

        DummyClassForMongoid.expects(:__find_in_batches).returns( [:a, :b] )

        DummyClassForMongoid.__find_in_batches(preprocess: :update_batch) do |batch|
          assert_same_elements ["a!", "b!"], batch
        end
      end

      context "when transforming models" do
        setup do
          @transform = DummyClassForMongoid.__transform
        end

        should "provide an object that responds to #call" do
          assert_respond_to @transform, :call
        end

        should "provide default transformation" do
          model = mock("model", id: 1, as_indexed_json: {})
          assert_equal @transform.call(model), { index: { _id: "1", data: {} } }
        end
      end
    end

  end
end
