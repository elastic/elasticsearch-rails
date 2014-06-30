require 'test_helper'

puts "ActiveRecord #{ActiveRecord::VERSION::STRING}", '-'*80

module Elasticsearch
  module Model
    class ActiveRecordDefaultScopeIntegrationTest < Elasticsearch::Test::IntegrationTestCase

      class ::ArticleWithDefaultScope < ActiveRecord::Base
        include Elasticsearch::Model
        include Elasticsearch::Model::Callbacks

        default_scope -> {
          where(status: :published)
        }

        settings index: { number_of_shards: 1, number_of_replicas: 0 } do
          mapping do
            indexes :title,      type: 'string', analyzer: 'snowball'
            indexes :status,     type: 'string', analyzer: 'not_analyzed'
          end
        end
      end

      context "ActiveRecord default_scope integration" do
        setup do
          ActiveRecord::Schema.define(:version => 1) do
            create_table :article_with_default_scopes do |t|
              t.string   :title
              t.string   :status
            end
          end

          ArticleWithDefaultScope.delete_all
          ArticleWithDefaultScope.__elasticsearch__.create_index! force: true

          ::ArticleWithDefaultScope.create! title: 'Test', status: :draft
          ::ArticleWithDefaultScope.create! title: 'Test', status: :published

          ArticleWithDefaultScope.__elasticsearch__.refresh_index!
        end

        should "find all document" do
          response = ArticleWithDefaultScope.search('title:test')

          assert response.any?, "Response should not be empty: #{response.to_a.inspect}"

          assert_equal 2, response.results.size
          assert_equal 2, response.records.size
        end
      end
    end
  end
end
