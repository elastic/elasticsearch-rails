require 'test_helper'

class Elasticsearch::Model::RecordsTest < Test::Unit::TestCase
  context "Response records" do
    class DummyCollection
      include Enumerable

      def each(&block); ['FOO'].each(&block); end
      def size;         ['FOO'].size;         end
      def empty?;       ['FOO'].empty?;       end
      def foo;          'BAR';                end
    end

    class DummyClass
      def self.find(*args)
        DummyCollection.new
      end
    end

    RESPONSE = { 'hits' => { 'total' => 123, 'max_score' => 456, 'hits' => [{'foo' => 'bar'}] } }
    RESULTS  = Elasticsearch::Model::Response::Results.new DummyClass, RESPONSE

    setup do
      @records = Elasticsearch::Model::Response::Records.new DummyClass,
                                                             RESPONSE,
                                                             RESULTS
    end

    should "access the records" do
      assert_respond_to @records, :records
      assert_equal 1, @records.records.size
      assert_equal 'FOO', @records.records.first
    end

    should "delegate Enumerable methods to records" do
      assert ! @records.empty?
      assert_equal 'FOO', @records.first
    end

    should "delegate methods to records" do
      assert_respond_to   @records, :foo
      assert_equal 'BAR', @records.foo
    end

    should "have each_with_hit method" do
      @records.each_with_hit do |record, hit|
        assert_equal 'FOO', record
        assert_equal 'bar', hit.foo
      end
    end

    should "have map_with_hit method" do
      assert_equal ['FOO---bar'], @records.map_with_hit { |record, hit| "#{record}---#{hit.foo}" }
    end

    context "with adapter" do
      module DummyAdapter
        module RecordsMixin
          def records
            ['FOOBAR']
          end
        end

        def records_mixin
          RecordsMixin
        end; module_function :records_mixin
      end

      should "delegate the records method to the adapter" do
        Elasticsearch::Model::Adapter.expects(:from_class)
                                     .with(DummyClass)
                                     .returns(DummyAdapter)

        @records = Elasticsearch::Model::Response::Records.new DummyClass,
                                                               RESPONSE,
                                                               RESULTS

        assert_equal ['FOOBAR'], @records.records
      end
    end

  end
end
