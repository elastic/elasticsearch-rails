require 'test_helper'
require 'active_record'

puts "ActiveRecord #{ActiveRecord::VERSION::STRING}", '-'*80

module Elasticsearch
  module Model
    class ActiveRecordBasicIntegrationTest < Elasticsearch::Test::IntegrationTestCase
      context "ActiveRecord basic integration" do
        setup do
          ActiveRecord::Schema.define(:version => 1) do
            create_table :articles do |t|
              t.string   :title
              t.datetime :created_at, :default => 'NOW()'
            end
          end

          class ::Article < ActiveRecord::Base
            include Elasticsearch::Model
            include Elasticsearch::Model::Callbacks

            settings index: { number_of_shards: 1, number_of_replicas: 0 } do
              mapping do
                indexes :title,      type: 'string', analyzer: 'snowball'
                indexes :created_at, type: 'date'
              end
            end
          end

          Article.delete_all
          Article.__elasticsearch__.create_index! force: true

          ::Article.create! title: 'Test'
          ::Article.create! title: 'Testing Coding'
          ::Article.create! title: 'Coding'

          Article.__elasticsearch__.refresh_index!
        end

        should "index and find a document" do
          response = Article.search('title:test')

          assert response.any?, "Response should not be empty: #{response.to_a.inspect}"

          assert_equal 2, response.results.size
          assert_equal 2, response.records.size

          assert_instance_of Elasticsearch::Model::Response::Result, response.results.first
          assert_instance_of Article, response.records.first

          assert_equal 'Test', response.results.first.title
          assert_equal 'Test', response.records.first.title
        end

        should "provide access to result" do
          response = Article.search query: { match: { title: 'test' } }, highlight: { fields: { title: {} } }

          assert_equal 'Test', response.results.first.title

          assert_equal true,  response.results.first.title?
          assert_equal false, response.results.first.boo?

          assert_equal true,  response.results.first.highlight?
          assert_equal true,  response.results.first.highlight.title?
          assert_equal false, response.results.first.highlight.boo?
        end

        should "iterate over results" do
          response = Article.search('title:test')

          assert_equal ['1', '2'], response.results.map(&:_id)
          assert_equal [1, 2],     response.records.map(&:id)
        end

        should "return _id and _type as #id and #type" do
          response = Article.search('title:test')

          assert_equal '1',       response.results.first.id
          assert_equal 'article', response.results.first.type
        end

        should "access results from records" do
          response = Article.search('title:test')

          response.records.each_with_hit do |r, h|
            assert_not_nil h._score
            assert_not_nil h._source.title
          end
        end

        should "preserve the search results order for records" do
          response = Article.search('title:code')

          response.records.each_with_hit do |r, h|
            assert_equal h._id, r.id.to_s
          end

          response.records.map_with_hit do |r, h|
            assert_equal h._id, r.id.to_s
          end
        end

        should "remove document from index on destroy" do
          article = Article.first

          article.destroy
          assert_equal 2, Article.count

          Article.__elasticsearch__.refresh_index!

          response = Article.search 'title:test'

          assert_equal 1, response.results.size
          assert_equal 1, response.records.size
        end

        should "index updates to the document" do
          article = Article.first

          article.title = 'Writing'
          article.save

          Article.__elasticsearch__.refresh_index!

          response = Article.search 'title:write'

          assert_equal 1, response.results.size
          assert_equal 1, response.records.size
        end

         should "update specific attributes" do
          article = Article.first

          response = Article.search 'title:special'

          assert_equal 0, response.results.size
          assert_equal 0, response.records.size

          article.__elasticsearch__.update_document_attributes title: 'special'

          Article.__elasticsearch__.refresh_index!

          response = Article.search 'title:special'

          assert_equal 1, response.results.size
          assert_equal 1, response.records.size
        end

        should "return results for a DSL search" do
          response = Article.search query: { match: { title: { query: 'test' } } }

          assert_equal 2, response.results.size
          assert_equal 2, response.records.size
        end

        should "return a paged collection" do
          response = Article.search query: { match: { title: { query: 'test' } } },
                                    size: 2,
                                    from: 1

          assert_equal 1, response.results.size
          assert_equal 1, response.records.size

          assert_equal 'Testing Coding', response.results.first.title
          assert_equal 'Testing Coding', response.records.first.title
        end

        should "allow chaining SQL commands on response.records" do
          response = Article.search query: { match: { title: { query: 'test' } } }

          assert_equal 2,      response.records.size
          assert_equal 1,      response.records.where(title: 'Test').size
          assert_equal 'Test', response.records.where(title: 'Test').first.title
        end

        should "allow ordering response.records in SQL" do
          response = Article.search query: { match: { title: { query: 'test' } } }

          if defined?(::ActiveRecord) && ::ActiveRecord::VERSION::MAJOR >= 4
            assert_equal 'Testing Coding', response.records.order(title: :desc).first.title
          else
            assert_equal 'Testing Coding', response.records.order('title DESC').first.title
          end
        end

        should "allow dot access to response" do
          response = Article.search query: { match: { title: { query: 'test' } } },
                                    aggregations: { dates: { date_histogram: { field: 'created_at', interval: 'hour' } } }

          response.response.respond_to?(:aggregations)
          assert_equal 2, response.response.aggregations.dates.buckets.first.doc_count
        end
      end

    end
  end
end
