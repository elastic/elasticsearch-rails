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

        should "save and find a plain hash" do
          @repository.save id: 1, title: 'Hash'
          result = @repository.find(1)
          assert_equal 'Hash', result['_source']['title']
        end
      end

    end
  end
end
