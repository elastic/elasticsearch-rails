require 'test_helper'

class Elasticsearch::Model::MultipleTest < Test::Unit::TestCase

  context "Adapter for multiple models" do

    class ::DummyOne
      include Elasticsearch::Model

      index_name 'dummy'
      document_type 'dummy_one'

      def self.find(ids)
        ids.map { |id| new(id) }
      end

      attr_reader :id

      def initialize(id)
        @id = id.to_i
      end
    end

    module ::Namespace
      class DummyTwo
        include Elasticsearch::Model

        index_name 'dummy'
        document_type 'dummy_two'

        def self.find(ids)
          ids.map { |id| new(id) }
        end

        attr_reader :id

        def initialize(id)
          @id = id.to_i
        end
      end
    end

    class ::DummyTwo
      include Elasticsearch::Model

      index_name 'other_index'
      document_type 'dummy_two'

      def self.find(ids)
        ids.map { |id| new(id) }
      end

      attr_reader :id

      def initialize(id)
        @id = id.to_i
      end
    end

    HITS = [{_index: 'dummy',
             _type: 'dummy_two',
             _id: '2',
            }, {
              _index: 'dummy',
              _type: 'dummy_one',
              _id: '2',
            }, {
              _index: 'other_index',
              _type: 'dummy_two',
              _id: '1',
            }, {
              _index: 'dummy',
              _type: 'dummy_two',
              _id: '1',
            }, {
              _index: 'dummy',
              _type: 'dummy_one',
              _id: '3'}]

    setup do
      @multimodel = Elasticsearch::Model::Multimodel.new(DummyOne, DummyTwo, Namespace::DummyTwo)
    end

    context "when returning records" do
      setup do
        @multimodel.class.send :include, Elasticsearch::Model::Adapter::Multiple::Records
        @multimodel.expects(:response).at_least_once.returns(stub(response: { 'hits' => { 'hits' => HITS } }))
      end

      should "keep the order from response" do
        assert_instance_of Module, Elasticsearch::Model::Adapter::Multiple::Records
        records = @multimodel.records

        assert_equal 5, records.count

        assert_kind_of ::Namespace::DummyTwo, records[0]
        assert_kind_of ::DummyOne,            records[1]
        assert_kind_of ::DummyTwo,            records[2]
        assert_kind_of ::Namespace::DummyTwo, records[3]
        assert_kind_of ::DummyOne,            records[4]

        assert_equal [2, 2, 1, 1, 3], records.map(&:id)
      end
    end
  end
end
