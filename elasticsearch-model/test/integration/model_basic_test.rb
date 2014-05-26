require 'test_helper'
require 'elasticsearch/model'

module Elasticsearch
  module Model
    class ModelBasicIntgrationTest < Elasticsearch::Test::IntegrationTestCase

      class ArticleModel
        include ActiveModel::Model
        include Elasticsearch::Model

        attr_accessor :id, :title

        def self.create!(attrs={})
          new(attrs).__elasticsearch__.index_document
        end

        def as_indexed_json(options={})
          {id: id, title: title}
        end
      end

      class AuthorModel
        include ActiveModel::Model
        include Elasticsearch::Model

        attr_accessor :id, :name, :title

        def self.create!(attrs={})
          new(attrs).__elasticsearch__.index_document
        end

        def as_indexed_json(options={})
          {id: id, title: title, name: name}
        end
      end

      context "Model search" do
        setup do
          ArticleModel.create! id: 1, title: 'Test'
          AuthorModel.create!  id: 1, title: 'Mr', name: "Jack White"
        end

        should "search specific model" do
          response = Elasticsearch::Model.search('test white', [ArticleModel])
          assert_equal response.results.total, 1
        end

        should "search across multiple models" do
          response = Elasticsearch::Model.search('test white', [ArticleModel, AuthorModel])
          assert_equal response.results.total, 2
        end

        should "search across all models" do
          MultipleModels.any_instance.expects(:__searchable_models).returns([ArticleModel, AuthorModel])

          response = Elasticsearch::Model.search('test white')
          assert_equal response.results.total, 2
        end

      end
    end
  end
end
