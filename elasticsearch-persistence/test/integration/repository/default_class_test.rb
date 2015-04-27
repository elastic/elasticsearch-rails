require 'test_helper'

module Elasticsearch
  module Persistence
    class RepositoryDefaultClassIntegrationTest < Elasticsearch::Test::IntegrationTestCase

      class ::Note
        attr_reader :attributes

        def initialize(attributes={})
          @attributes = attributes
        end

        def to_hash
          @attributes
        end
      end

      context "The default repository class" do
        setup do
          @repository = Elasticsearch::Persistence::Repository.new
          @repository.client.cluster.health wait_for_status: 'yellow'
        end

        should "save the object with a custom ID and find it" do
          @repository.save Note.new(id: '1', title: 'Test')

          assert_equal 'Test', @repository.find(1).attributes['title']
        end

        should "save the object with an auto-generated ID and find it" do
          response = @repository.save Note.new(title: 'Test')

          assert_equal 'Test', @repository.find(response['_id']).attributes['title']
        end

        should "update the document" do
          @repository.save Note.new(id: 1, title: 'Test')

          @repository.update 1, type: 'note', doc: { title: 'UPDATED' }
          assert_equal 'UPDATED', @repository.find(1).attributes['title']
        end

        should "update the document with a script" do
          @repository.save Note.new(id: 1, title: 'Test')

          @repository.update 1, type: 'note', script: 'ctx._source.title = "UPDATED"'
          assert_equal 'UPDATED', @repository.find(1).attributes['title']
        end

        should "save the document with an upsert" do
          @repository.update 1, type: 'note', script: 'ctx._source.clicks += 1', upsert: { clicks: 1 }
          assert_equal 1, @repository.find(1).attributes['clicks']
        end

        should "delete an object" do
          note = Note.new(id: '1', title: 'Test')

          @repository.save(note)
          assert_not_nil @repository.find(1)
          @repository.delete(note)
          assert_raise(Elasticsearch::Persistence::Repository::DocumentNotFound) { @repository.find(1) }
        end

        should "find multiple objects" do
          (1..5).each { |i| @repository.save Note.new(id: i, title: "Test #{i}") }

          assert_equal 5, @repository.find(1, 2, 3, 4, 5).size
          assert_equal 5, @repository.find([1, 2, 3, 4, 5]).size
        end

        should "pass options to save and find" do
          note = Note.new(id: '1', title: 'Test')
          @repository.save note, routing: 'ABC'

          @repository.client.cluster.health level: 'indices', wait_for_status: 'yellow'

          assert_raise Elasticsearch::Persistence::Repository::DocumentNotFound do
            @repository.find(1, routing: 'DEF')
          end

          assert_nothing_raised do
            note = @repository.find(1, routing: 'ABC')
            assert_instance_of Note, note
          end
        end

        should "find notes with full text search" do
          @repository.save Note.new(title: 'Test')
          @repository.save Note.new(title: 'Test Test')
          @repository.save Note.new(title: 'Crust')
          @repository.client.indices.refresh index: @repository.index_name

          results = @repository.search 'test'
          assert_equal 2, results.size

          results = @repository.search query: { match: { title: 'Test' } }
          assert_equal 2, results.size
        end

        should "count notes" do
          @repository.save Note.new(title: 'Test')
          @repository.client.indices.refresh index: @repository.index_name
          assert_equal 1, @repository.count
        end

        should "save and find a plain hash" do
          @repository.save id: 1, title: 'Hash'
          result = @repository.find(1)
          assert_equal 'Hash', result['_source']['title']
        end
      end

    end
  end
end
