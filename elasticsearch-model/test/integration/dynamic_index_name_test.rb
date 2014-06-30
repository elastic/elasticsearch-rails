require 'test_helper'

module Elasticsearch
  module Model
    class DynamicIndexNameTest < Elasticsearch::Test::IntegrationTestCase

      class ::ArticleWithDynamicIndexName < ActiveRecord::Base
        include Elasticsearch::Model
        include Elasticsearch::Model::Callbacks

        class << self
          attr_accessor :year
        end

        mapping { indexes :title }
        index_name { "articles-#{year}" }
      end

      context "Dynamic index name" do
        setup do
          ActiveRecord::Schema.define(:version => 1) do
            create_table :article_with_dynamic_index_names do |t|
              t.string   :title
            end
          end
        end

        should 'evaluate the index_name value' do
          ArticleWithDynamicIndexName.year = '2014'

          assert_equal ArticleWithDynamicIndexName.index_name, "articles-2014"
        end

        should 'reevaluate the index_name value each time' do
          ArticleWithDynamicIndexName.year = '2015'

          assert_equal ArticleWithDynamicIndexName.index_name, "articles-2015"
        end

        should "write and read at the the defined index" do
          ArticleWithDynamicIndexName.year = '2016'

          ArticleWithDynamicIndexName.delete_all
          ArticleWithDynamicIndexName.__elasticsearch__.create_index! force: true

          ::ArticleWithDynamicIndexName.create! title: 'Test'

          ArticleWithDynamicIndexName.__elasticsearch__.refresh_index!

          response = ArticleWithDynamicIndexName.search(query: { match_all: {} })

          assert_equal response.results.total, 1
          assert_equal response.search.definition[:index], ArticleWithDynamicIndexName.index_name
          assert_equal response.search.definition[:index], 'articles-2016'
        end
      end

    end
  end
end
