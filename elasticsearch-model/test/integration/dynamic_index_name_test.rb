require 'test_helper'
require 'active_record'

module Elasticsearch
  module Model
    class DynamicIndexNameTest < Elasticsearch::Test::IntegrationTestCase
      context "Dynamic index name" do
        setup do
          class ::ArticleWithDynamicIndexName < ActiveRecord::Base
            include Elasticsearch::Model
            include Elasticsearch::Model::Callbacks

            def self.counter=(value)
              @counter = 0
            end

            def self.counter
              (@counter ||= 0) && @counter += 1
            end

            mapping    { indexes :title }
            index_name { "articles-#{counter}" }
          end

          ::ActiveRecord::Schema.define(:version => 1) do
            create_table ::ArticleWithDynamicIndexName.table_name do |t|
              t.string :title
            end
          end

          ::ArticleWithDynamicIndexName.counter = 0
        end

        should 'evaluate the index_name value' do
          assert_equal ArticleWithDynamicIndexName.index_name, "articles-1"
        end

        should 're-evaluate the index_name value each time' do
          assert_equal ArticleWithDynamicIndexName.index_name, "articles-1"
          assert_equal ArticleWithDynamicIndexName.index_name, "articles-2"
          assert_equal ArticleWithDynamicIndexName.index_name, "articles-3"
        end
      end

    end
  end
end
