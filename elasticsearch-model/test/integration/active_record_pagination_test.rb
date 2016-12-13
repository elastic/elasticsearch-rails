require 'test_helper'
require 'active_record'

# Needed for ActiveRecord 3.x ?
ActiveRecord::Base.establish_connection( :adapter => 'sqlite3', :database => ":memory:" ) unless ActiveRecord::Base.connected?

module Elasticsearch
  module Model
    class ActiveRecordPaginationTest < Elasticsearch::Test::IntegrationTestCase
      context "ActiveRecord pagination" do
        setup do
          class ::ArticleForPagination < ActiveRecord::Base
            include Elasticsearch::Model

            scope :published, -> { where(published: true) }

            settings index: { number_of_shards: 1, number_of_replicas: 0 } do
              mapping do
                indexes :title,      type: 'string', analyzer: 'snowball'
                indexes :created_at, type: 'date'
              end
            end
          end

          ActiveRecord::Schema.define(:version => 1) do
            create_table ::ArticleForPagination.table_name do |t|
              t.string   :title
              t.datetime :created_at, :default => 'NOW()'
              t.boolean  :published
            end
          end

          Kaminari::Hooks.init

          ArticleForPagination.delete_all
          ArticleForPagination.__elasticsearch__.create_index! force: true

          68.times do |i|
            ::ArticleForPagination.create! title: "Test #{i}", published: (i % 2 == 0)
          end

          ArticleForPagination.import
          ArticleForPagination.__elasticsearch__.refresh_index!
        end

        should "be on the first page by default" do
          records = ArticleForPagination.search('title:test').page(1).records

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
          records = ArticleForPagination.search('title:test').page(2).records

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
          records = ArticleForPagination.search('title:test').page(3).records

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
          records = ArticleForPagination.search('title:test').page(6).records

          assert_equal 0, records.size
          assert_equal 6, records.current_page
          assert_equal 5, records.prev_page
          assert_equal nil, records.next_page
          assert_equal 3, records.total_pages

          assert ! records.first_page?,   "Should NOT be the first page"
          assert   records.last_page?,    "Should be the last page"
          assert   records.out_of_range?, "Should be out of range"
        end

        should "be combined with scopes" do
          records = ArticleForPagination.search('title:test').page(2).records.published
          assert records.all? { |r| r.published? }
          assert_equal 12, records.size
        end

        should "respect sort" do
          search = ArticleForPagination.search({ query: { match: { title: 'test' } }, sort: [ { id: 'desc' } ] })

          records = search.page(2).records
          assert_equal 43, records.first.id         # 68 - 25 = 42

          records = search.page(3).records
          assert_equal 18, records.first.id         # 68 - (2 * 25) = 18

          records = search.page(2).per(5).records
          assert_equal 63, records.first.id         # 68 - 5 = 63
        end

        should "set the limit per request" do
          records = ArticleForPagination.search('title:test').limit(50).page(2).records

          assert_equal 18,  records.size
          assert_equal 2,   records.current_page
          assert_equal 1,   records.prev_page
          assert_equal nil, records.next_page
          assert_equal 2,   records.total_pages

          assert records.last_page?, "Should be the last page"
        end

        context "with specific model settings" do
          teardown do
            ArticleForPagination.instance_variable_set(:@_default_per_page, nil)
          end

          should "respect paginates_per" do
            ArticleForPagination.paginates_per 50

            assert_equal 50, ArticleForPagination.search('*').page(1).records.size
          end
        end
      end

    end
  end
end
