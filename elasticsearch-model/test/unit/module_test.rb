require 'test_helper'

class Elasticsearch::Model::ModuleTest < Test::Unit::TestCase
  context "The main module" do

    context "client" do
      should "have a default" do
        client = Elasticsearch::Model.client
        assert_not_nil     client
        assert_instance_of Elasticsearch::Transport::Client, client
      end

      should "be settable" do
        begin
          Elasticsearch::Model.client = "Foobar"
          assert_equal "Foobar", Elasticsearch::Model.client
        ensure
          Elasticsearch::Model.client = nil
        end
      end
    end

    context "when included in module/class, " do
      class ::DummyIncludingModel; end
      class ::DummyIncludingModelWithSearchMethodDefined
        def self.search(query, options={})
          "SEARCH"
        end
      end

      should "include and set up the proxy" do
        DummyIncludingModel.__send__ :include, Elasticsearch::Model

        assert_respond_to DummyIncludingModel,     :__elasticsearch__
        assert_respond_to DummyIncludingModel.new, :__elasticsearch__
      end

      should "delegate important methods to the proxy" do
        DummyIncludingModel.__send__ :include, Elasticsearch::Model

        assert_respond_to DummyIncludingModel, :search
        assert_respond_to DummyIncludingModel, :mappings
        assert_respond_to DummyIncludingModel, :settings
        assert_respond_to DummyIncludingModel, :index_name
        assert_respond_to DummyIncludingModel, :document_type
        assert_respond_to DummyIncludingModel, :import
      end

      should "not override existing method" do
        DummyIncludingModelWithSearchMethodDefined.__send__ :include, Elasticsearch::Model

        assert_equal 'SEARCH', DummyIncludingModelWithSearchMethodDefined.search('foo')
      end
    end

  end
end
