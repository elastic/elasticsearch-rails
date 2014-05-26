require 'test_helper'

class Elasticsearch::Model::MultipleModelsTest < Test::Unit::TestCase
  context "initializing" do
    class ::DummySearchableModel
      include Elasticsearch::Model
    end

    context "with multiple models" do
      setup do
        @model_one = mock('ModelOne')
        @model_one.stubs(index_name: 'model_one', document_type: 'model_one_type')

        @model_two = mock('ModelTwo')
        @model_two.stubs(index_name: 'model_two', document_type: 'model_two_type')

        @multiple_models = Elasticsearch::Model::MultipleModels.new([@model_one, @model_two])
      end

      should "enumerate only specified models" do
        assert_equal    @multiple_models.size, 2
        assert_includes @multiple_models, @model_one
        assert_includes @multiple_models, @model_two
      end

      should "define indexes to search" do
        assert_equal @multiple_models.index_name, ['model_one', 'model_two']
      end

      should "define document type to search" do
        assert_equal @multiple_models.document_type, ['model_one_type', 'model_two_type']
      end

      should "have specific default per page" do
        assert_equal @multiple_models.default_per_page, 10
      end

      should "have no ancestors" do
        assert_equal @multiple_models.ancestors, []
      end

      should "have access to the model client" do
        begin
          Elasticsearch::Model.client = "Foobar"
          assert_equal @multiple_models.client, Elasticsearch::Model.client
        ensure
          Elasticsearch::Model.client = nil
        end
      end

      should "respond to inspect" do
        assert_equal @multiple_models.inspect, "MultipleModels: #{[@model_one, @model_two].inspect}"
      end
    end

    should "enumerate all available elasticsearch models" do
      Object.expects(:constants).returns([:DummySearchableModel])

      multiple_models = Elasticsearch::Model::MultipleModels.new
      assert_includes multiple_models, DummySearchableModel
      assert_equal    multiple_models.size, 1
    end
  end
end
