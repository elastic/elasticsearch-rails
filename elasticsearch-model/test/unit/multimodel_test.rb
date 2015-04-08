require 'test_helper'

class Elasticsearch::Model::MultimodelTest < Test::Unit::TestCase

  context "Multimodel class" do
    setup do
      title  = stub('Foo', index_name: 'foo_index', document_type: 'foo')
      series = stub('Bar', index_name: 'bar_index', document_type: 'bar')
      @multimodel = Elasticsearch::Model::Multimodel.new(title, series)
    end

    should "have an index_name" do
      assert_equal ['foo_index', 'bar_index'], @multimodel.index_name
    end

    should "have a document_type" do
      assert_equal ['foo', 'bar'], @multimodel.document_type
    end

    should "have a client" do
      assert_equal Elasticsearch::Model.client, @multimodel.client
    end

    should "include models in the registry" do
      class ::JustAModel
        include Elasticsearch::Model
      end

      class ::JustAnotherModel
        include Elasticsearch::Model
      end

      multimodel = Elasticsearch::Model::Multimodel.new
      assert multimodel.models.include?(::JustAModel)
      assert multimodel.models.include?(::JustAnotherModel)
    end
  end
end
