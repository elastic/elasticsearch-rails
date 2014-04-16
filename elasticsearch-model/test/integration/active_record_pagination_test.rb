require 'test_helper'

module Elasticsearch
  module Model
    class ActiveRecordPaginationTest < Elasticsearch::Test::IntegrationTestCase

      class ::Article < ActiveRecord::Base
        include Elasticsearch::Model

        settings index: { number_of_shards: 1, number_of_replicas: 0 } do
          mapping do
            indexes :title,      type: 'string', analyzer: 'snowball'
            indexes :created_at, type: 'date'
          end
        end
      end

      Kaminari::Hooks.init

      context "ActiveRecord pagination" do
        setup do
          ActiveRecord::Schema.define(:version => 1) do
            create_table :articles do |t|
              t.string   :title
              t.datetime :created_at, :default => 'NOW()'
            end
          end

          Article.delete_all
          Article.__elasticsearch__.create_index! force: true

          68.times do |i| ::Article.create! title: "Test #{i}" end

          Article.import
          Article.__elasticsearch__.refresh_index!
        end

        should "be on the first page by default" do
          records = Article.search('title:test').page(1).records

          assert_equal 25, records.size
          assert_equal 1, records.current_page
          assert_equal nil, records.prev_page
          assert_equal 2, records.next_page
          assert_equal 3, records.total_pages

          assert   records.first_page?,   "Should be the first page"
          assert ! records.last_page?,    "Should NOT be the last page"
          assert ! records.out_of_range?, "Should NOT be out of range"
        end

        should "load next page" do
          records = Article.search('title:test').page(2).records

          assert_equal 25, records.size
          assert_equal 2, records.current_page
          assert_equal 1, records.prev_page
          assert_equal 3, records.next_page
          assert_equal 3, records.total_pages

          assert ! records.first_page?,   "Should NOT be the first page"
          assert ! records.last_page?,    "Should NOT be the last page"
          assert ! records.out_of_range?, "Should NOT be out of range"
        end

        should "load last page" do
          records = Article.search('title:test').page(3).records

          assert_equal 18, records.size
          assert_equal 3, records.current_page
          assert_equal 2, records.prev_page
          assert_equal nil, records.next_page
          assert_equal 3, records.total_pages

          assert ! records.first_page?,   "Should NOT be the first page"
          assert   records.last_page?,    "Should be the last page"
          assert ! records.out_of_range?, "Should NOT be out of range"
        end

        should "not load invalid page" do
          records = Article.search('title:test').page(6).records

          assert_equal 0, records.size
          assert_equal 6, records.current_page
          assert_equal 5, records.prev_page
          assert_equal nil, records.next_page
          assert_equal 3, records.total_pages

          assert ! records.first_page?,   "Should NOT be the first page"
          assert   records.last_page?,    "Should be the last page"
          assert   records.out_of_range?, "Should be out of range"
        end

        context "with specific model settings" do
          teardown do
            Article.instance_variable_set(:@_default_per_page, nil)
          end
        end

        should "respect paginates_per" do
          Article.paginates_per 50

          assert_equal 50, Article.search('*').page(1).records.size
        end
      end

    end
  end
end
