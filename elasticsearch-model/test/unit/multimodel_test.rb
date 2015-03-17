require 'test_helper'

class Elasticsearch::Model::MultimodelTest < Test::Unit::TestCase

  context "Multimodel class" do
    setup do
      title  = stub('Title',  index_name: 'titles_index', document_type: 'title')
      series = stub('Series', index_name: 'series_index', document_type: 'series')
      @multimodel = Elasticsearch::Model::Multimodel.new(title, series)
    end

    should "#index_name" do
      assert_equal ['titles_index', 'series_index'], @multimodel.index_name
    end

    should "#document_type" do
      assert_equal ['title', 'series'], @multimodel.document_type
    end

    should "#client" do
      assert_equal Elasticsearch::Model.client, @multimodel.client
    end

    should "default intialization" do
      class ::JustAModel
        include Elasticsearch::Model

        document_type "just_a_model"
      end

      class ::JustAnotherModel
        include Elasticsearch::Model

        document_type "just_another_model"
      end

      multimodel = Elasticsearch::Model::Multimodel.new
      assert multimodel.models.include?(::JustAModel)
      assert multimodel.models.include?(::JustAnotherModel)
    end
  end
end
