require 'test_helper'
require 'active_record'

# Needed for ActiveRecord 3.x ?
ActiveRecord::Base.establish_connection( :adapter => 'sqlite3', :database => ":memory:" ) unless ActiveRecord::Base.connected?

::ActiveRecord::Base.raise_in_transactional_callbacks = true if ::ActiveRecord::Base.respond_to?(:raise_in_transactional_callbacks) && ::ActiveRecord::VERSION::MAJOR.to_s < '5'

module Elasticsearch
  module Model
    class ActiveRecordImportIntegrationTest < Elasticsearch::Test::IntegrationTestCase

      context "ActiveRecord importing" do
        setup do
          Object.send(:remove_const, :ImportArticle) if defined?(ImportArticle)
          class ::ImportArticle < ActiveRecord::Base
            include Elasticsearch::Model

            scope :popular, -> { where('views >= 50') }

            mapping do
              indexes :title,      type: 'text'
              indexes :views,      type: 'integer'
              indexes :numeric,    type: 'integer'
              indexes :created_at, type: 'date'
            end
          end

          ActiveRecord::Schema.define(:version => 1) do
            create_table :import_articles do |t|
              t.string   :title
              t.integer  :views
              t.string   :numeric # For the sake of invalid data sent to Elasticsearch
              t.datetime :created_at, :default => 'NOW()'
            end
          end

          ImportArticle.delete_all
          ImportArticle.__elasticsearch__.create_index! force: true
          ImportArticle.__elasticsearch__.client.cluster.health wait_for_status: 'yellow'

          100.times { |i| ImportArticle.create! title: "Test #{i}", views: i }
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

        should "import only documents from a specific scope" do
          assert_equal 100, ImportArticle.count

          assert_equal 0, ImportArticle.import(scope: 'popular')

          ImportArticle.__elasticsearch__.refresh_index!
          assert_equal 50, ImportArticle.search('*').results.total
        end

        should "import only documents from a specific query" do
          assert_equal 100, ImportArticle.count

          assert_equal 0, ImportArticle.import(query: -> { where('views >= 30') })

          ImportArticle.__elasticsearch__.refresh_index!
          assert_equal 70, ImportArticle.search('*').results.total
        end

        should "report and not store/index invalid documents" do
          ImportArticle.create! title: "Test INVALID", numeric: "INVALID"

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

        should "transform documents with the option" do
          assert_equal 100, ImportArticle.count

          assert_equal 0, ImportArticle.import( transform: ->(a) {{ index: { data: { name: a.title, foo: 'BAR' } }}} )

          ImportArticle.__elasticsearch__.refresh_index!
          assert_contains ImportArticle.search('*').results.first._source.keys, 'name'
          assert_contains ImportArticle.search('*').results.first._source.keys, 'foo'
          assert_equal 100, ImportArticle.search('test').results.total
          assert_equal 100, ImportArticle.search('bar').results.total
        end
      end

      context "ActiveRecord importing when the model has a default scope" do

        setup do
          Object.send(:remove_const, :ImportArticle) if defined?(ImportArticle)
          class ::ImportArticle < ActiveRecord::Base
            include Elasticsearch::Model

            default_scope { where('views >= 8') }

            mapping do
              indexes :title,      type: 'text'
              indexes :views,      type: 'integer'
              indexes :numeric,    type: 'integer'
              indexes :created_at, type: 'date'
            end
          end

          ActiveRecord::Schema.define(:version => 1) do
            create_table :import_articles do |t|
              t.string   :title
              t.integer  :views
              t.string   :numeric # For the sake of invalid data sent to Elasticsearch
              t.datetime :created_at, :default => 'NOW()'
            end
          end

          ImportArticle.delete_all
          ImportArticle.__elasticsearch__.delete_index! force: true
          ImportArticle.__elasticsearch__.create_index! force: true
          ImportArticle.__elasticsearch__.client.cluster.health wait_for_status: 'yellow'

          10.times { |i| ImportArticle.create! title: "Test #{i}", views: i }
        end

        should "import only documents from the default scope" do
          assert_equal 2, ImportArticle.count

          assert_equal 0, ImportArticle.import

          ImportArticle.__elasticsearch__.refresh_index!
          assert_equal 2, ImportArticle.search('*').results.total
        end

        should "import only documents from a specific query combined with the default scope" do
          assert_equal 2, ImportArticle.count

          assert_equal 0, ImportArticle.import(query: -> { where("title = 'Test 9'") })

          ImportArticle.__elasticsearch__.refresh_index!
          assert_equal 1, ImportArticle.search('*').results.total
        end
      end

      context 'ActiveRecord importing when the batch is empty' do

        setup do
          Object.send(:remove_const, :ImportArticle) if defined?(ImportArticle)
          class ::ImportArticle < ActiveRecord::Base
            include Elasticsearch::Model
            mapping { indexes :title, type: 'text' }
          end

          ActiveRecord::Schema.define(:version => 1) do
            create_table :import_articles do |t|
              t.string   :title
            end
          end

          ImportArticle.delete_all
          ImportArticle.__elasticsearch__.delete_index! force: true
          ImportArticle.__elasticsearch__.create_index! force: true
          ImportArticle.__elasticsearch__.client.cluster.health wait_for_status: 'yellow'
        end

        should 'not make any requests to create documents to Elasticsearch' do
          assert_equal 0, ImportArticle.count
          assert_equal 0, ImportArticle.import

          ImportArticle.__elasticsearch__.refresh_index!
          assert_equal 0, ImportArticle.search('*').results.total
        end
      end
    end
  end
end
