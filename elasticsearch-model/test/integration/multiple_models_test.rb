require 'test_helper'
require 'active_record'

# Needed for ActiveRecord 3.x ?
ActiveRecord::Base.establish_connection( :adapter => 'sqlite3', :database => ":memory:" ) unless ActiveRecord::Base.connected?

Mongo.setup!

module Elasticsearch
  module Model
    class MultipleModelsIntegration < Elasticsearch::Test::IntegrationTestCase
      module ::NameSearch
        extend ActiveSupport::Concern

        included do
          include Elasticsearch::Model
          include Elasticsearch::Model::Callbacks

          settings index: {number_of_shards: 1, number_of_replicas: 0} do
            mapping do
              indexes :name, type: 'string', analyzer: 'snowball'
              indexes :created_at, type: 'date'
            end
          end
        end
      end

      class ::Episode < ActiveRecord::Base
        include NameSearch
      end

      class ::Series < ActiveRecord::Base
        include NameSearch
      end

      context "Multiple models" do
        setup do
          ActiveRecord::Schema.define(:version => 1) do
            create_table :episodes do |t|
              t.string :name
              t.datetime :created_at, :default => 'NOW()'
            end

            create_table :series do |t|
              t.string :name
              t.datetime :created_at, :default => 'NOW()'
            end
          end

          [::Episode, ::Series].each do |model|
            model.delete_all
            model.__elasticsearch__.create_index! force: true
            model.create name: "The #{model.name}"
            model.create name: "A great #{model.name}"
            model.create name: "The greatest #{model.name}"
            model.__elasticsearch__.refresh_index!
          end
        end

        should "find matching documents across multiple models" do
          response = Elasticsearch::Model.search(%q<"The greatest Episode"^2 OR "The greatest Series">, [Series, Episode])

          assert response.any?, "Response should not be empty: #{response.to_a.inspect}"

          assert_equal 2, response.results.size
          assert_equal 2, response.records.size

          assert_instance_of Elasticsearch::Model::Response::Result, response.results.first
          assert_instance_of Episode, response.records.first
          assert_instance_of Series, response.records.last

          assert_equal 'The greatest Episode', response.results[0].name
          assert_equal 'The greatest Episode', response.records[0].name

          assert_equal 'The greatest Series', response.results[1].name
          assert_equal 'The greatest Series', response.records[1].name
        end

        should "provide access to results" do
          response = Elasticsearch::Model.search(%q<"A great Episode"^2 OR "A great Series">, [Series, Episode])

          assert_equal 'A great Episode', response.results[0].name
          assert_equal true,              response.results[0].name?
          assert_equal false,             response.results[0].boo?

          assert_equal 'A great Series', response.results[1].name
          assert_equal true,             response.results[1].name?
          assert_equal false,            response.results[1].boo?
        end

        should "only retrieve records for existing results" do
          ::Series.find_by_name("The greatest Series").delete
          ::Series.__elasticsearch__.refresh_index!
          response = Elasticsearch::Model.search(%q<"The greatest Episode"^2 OR "The greatest Series">, [Series, Episode])

          assert response.any?, "Response should not be empty: #{response.to_a.inspect}"

          assert_equal 2, response.results.size
          assert_equal 1, response.records.size

          assert_instance_of Elasticsearch::Model::Response::Result, response.results.first
          assert_instance_of Episode, response.records.first

          assert_equal 'The greatest Episode', response.results[0].name
          assert_equal 'The greatest Episode', response.records[0].name
        end

        should "paginate the results" do
          response = Elasticsearch::Model.search('series OR episode', [Series, Episode])

          assert_equal 3, response.page(1).per(3).results.size
          assert_equal 3, response.page(2).per(3).results.size
          assert_equal 0, response.page(3).per(3).results.size
        end

        if Mongo.available?
          Mongo.connect_to 'mongoid_collections'

          context "Across mongoid models" do
            setup do
              class ::Image
                include Mongoid::Document
                include Elasticsearch::Model
                include Elasticsearch::Model::Callbacks

                field :name, type: String
                attr_accessible :name if respond_to? :attr_accessible

                settings index: {number_of_shards: 1, number_of_replicas: 0} do
                  mapping do
                    indexes :name, type: 'string', analyzer: 'snowball'
                    indexes :created_at, type: 'date'
                  end
                end

                def as_indexed_json(options={})
                  as_json(except: [:_id])
                end
              end

              Image.delete_all
              Image.__elasticsearch__.create_index! force: true
              Image.create! name: "The Image"
              Image.create! name: "A great Image"
              Image.create! name: "The greatest Image"
              Image.__elasticsearch__.refresh_index!
              Image.__elasticsearch__.client.cluster.health wait_for_status: 'yellow'
            end

            should "find matching documents across multiple models" do
              response = Elasticsearch::Model.search(%q<"greatest Episode" OR "greatest Image"^2>, [Episode, Image])

              assert response.any?, "Response should not be empty: #{response.to_a.inspect}"

              assert_equal 2, response.results.size
              assert_equal 2, response.records.size

              assert_instance_of Elasticsearch::Model::Response::Result, response.results.first
              assert_instance_of Image, response.records.first
              assert_instance_of Episode, response.records.last

              assert_equal 'The greatest Image', response.results[0].name
              assert_equal 'The greatest Image', response.records[0].name

              assert_equal 'The greatest Episode', response.results[1].name
              assert_equal 'The greatest Episode', response.records[1].name
            end
          end
        end

      end
    end
  end
end
