require 'test_helper'

module Elasticsearch
  module Model
    class ActiveRecordImportIntegrationTest < Elasticsearch::Test::IntegrationTestCase

      class ::ImportArticle < ActiveRecord::Base
        include Elasticsearch::Model

        mapping do
          indexes :title,      type: 'string'
          indexes :views,      type: 'integer'
          indexes :created_at, type: 'date'
        end
      end

      context "ActiveRecord importing" do
        setup do
          ActiveRecord::Schema.define(:version => 1) do
            create_table :import_articles do |t|
              t.string   :title
              t.string   :views # For the sake of invalid data sent to Elasticsearch
              t.datetime :created_at, :default => 'NOW()'
            end
          end

          ImportArticle.delete_all
          ImportArticle.__elasticsearch__.create_index! force: true

          100.times { |i| ImportArticle.create! title: "Test #{i}" }
        end

        should "import all the documents" do
          assert_equal 100, ImportArticle.count

          ImportArticle.__elasticsearch__.refresh_index!
          assert_equal 0, ImportArticle.search('*').results.total

          batches = 0
          errors  = ImportArticle.import(batch_size: 10) do |response|
            batches += 1
          end

          assert_equal 0, errors
          assert_equal 10, batches

          ImportArticle.__elasticsearch__.refresh_index!
          assert_equal 100, ImportArticle.search('*').results.total
        end

        should "report and not store/index invalid documents" do
          ImportArticle.create! title: "Test INVALID", views: "INVALID"

          assert_equal 101, ImportArticle.count

          ImportArticle.__elasticsearch__.refresh_index!
          assert_equal 0, ImportArticle.search('*').results.total

          batches = 0
          errors  = ImportArticle.__elasticsearch__.import(batch_size: 10) do |response|
            batches += 1
          end

          assert_equal 1, errors
          assert_equal 11, batches

          ImportArticle.__elasticsearch__.refresh_index!
          assert_equal 100, ImportArticle.search('*').results.total
        end
      end

    end
  end
end
