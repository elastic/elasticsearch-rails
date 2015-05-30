require 'test_helper'

Mongo.setup!

if Mongo.available?
  Mongo.connect_to 'mongoid_articles'

  module Elasticsearch
    module Model
      class MongoidImportIntegrationTest < Elasticsearch::Test::IntegrationTestCase

        context "Mongoid importing" do
          setup do
            class ::MongoidImportArticle
              include Mongoid::Document
              include Elasticsearch::Model

              field :title,      type: String
              field :views,      type: Integer
              field :numeric,    type: String  # For the sake of invalid data sent to Elasticsearch
              field :created_at, type: Date

              scope :popular, -> { where(views: {'$gte' => 50 }) }

              mapping do
                indexes :title,      type: 'string'
                indexes :views,      type: 'integer'
                indexes :numeric,    type: 'integer'
                indexes :created_at, type: 'date'
              end

              def as_indexed_json(options = {})
                as_json(options).merge('_id' => self.id.to_s)
              end
            end

            MongoidImportArticle.delete_all
            MongoidImportArticle.__elasticsearch__.create_index! force: true
            MongoidImportArticle.__elasticsearch__.client.cluster.health wait_for_status: 'yellow'

            100.times { |i| MongoidImportArticle.create! title: "Test #{i}", views: i }
          end

          should "import all the documents" do
            assert_equal 100, MongoidImportArticle.count

            MongoidImportArticle.__elasticsearch__.refresh_index!
            assert_equal 0, MongoidImportArticle.search('*').results.total

            batches = 0
            errors  = MongoidImportArticle.import(batch_size: 10) do |response|
              batches += 1
            end

            assert_equal 0, errors
            assert_equal 10, batches

            MongoidImportArticle.__elasticsearch__.refresh_index!
            assert_equal 100, MongoidImportArticle.search('*').results.total
          end

          should "import only documents from a specific scope" do
            assert_equal 100, MongoidImportArticle.count

            assert_equal 0, MongoidImportArticle.import(scope: 'popular')

            MongoidImportArticle.__elasticsearch__.refresh_index!
            assert_equal 50, MongoidImportArticle.search('*').results.total
          end

          should "import only documents from a specific query" do
            assert_equal 100, MongoidImportArticle.count

            assert_equal 0, MongoidImportArticle.import(query: -> { where(views: { '$gte' => 30}) })

            MongoidImportArticle.__elasticsearch__.refresh_index!
            assert_equal 70, MongoidImportArticle.search('*').results.total
          end

          should "report and not store/index invalid documents" do
            MongoidImportArticle.create! title: "Test INVALID", numeric: "INVALID"
            assert_equal 101, MongoidImportArticle.count

            MongoidImportArticle.__elasticsearch__.refresh_index!
            assert_equal 0, MongoidImportArticle.search('*').results.total

            batches = 0
            errors  = MongoidImportArticle.__elasticsearch__.import(batch_size: 10) do |response|
              batches += 1
            end

            assert_equal 1, errors
            assert_equal 11, batches

            MongoidImportArticle.__elasticsearch__.refresh_index!
            assert_equal 100, MongoidImportArticle.search('*').results.total
          end

          should "transform documents with the option" do
            assert_equal 100, MongoidImportArticle.count

            assert_equal 0, MongoidImportArticle.import( transform: ->(a) {{ index: { data: { name: a.title, foo: 'BAR' } }}} )

            MongoidImportArticle.__elasticsearch__.refresh_index!
            assert_contains MongoidImportArticle.search('*').results.first._source.keys, 'name'
            assert_contains MongoidImportArticle.search('*').results.first._source.keys, 'foo'
            assert_equal 100, MongoidImportArticle.search('test').results.total
            assert_equal 100, MongoidImportArticle.search('bar').results.total
          end
        end

      end
    end
  end
end
