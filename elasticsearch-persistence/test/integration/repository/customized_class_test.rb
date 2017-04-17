require 'test_helper'

module Elasticsearch
  module Persistence
    class RepositoryCustomizedClassIntegrationTest < Elasticsearch::Test::IntegrationTestCase

      module ::My
        class Note
          attr_reader :attributes

          def initialize(attributes={})
            @attributes = attributes
          end

          def to_hash
            @attributes
          end
        end
      end

      context "A custom repository class" do
        setup do
          @repository = Elasticsearch::Persistence::Repository.new do
            index 'my_notes'
            type  'my_note'
            klass My::Note

            settings number_of_shards: 1 do
              mapping do
                indexes :title, analyzer: 'snowball'
              end
            end

            create_index!
          end

          @repository.client.cluster.health wait_for_status: 'yellow'
        end

        should "save the object under a correct index and type" do
          @repository.save My::Note.new(id: '1', title: 'Test')

          assert_instance_of My::Note, @repository.find(1)
          assert_not_nil Elasticsearch::Persistence.client.get index: 'my_notes', type: 'my_note', id: '1'
        end

        should "update the document" do
          @repository.save Note.new(id: 1, title: 'Test')

          @repository.update 1, doc: { title: 'UPDATED' }
          assert_equal 'UPDATED', @repository.find(1).attributes['title']
        end

        should "update the document with a script" do
          @repository.save Note.new(id: 1, title: 'Test')

          @repository.update 1, script: 'ctx._source.title = "UPDATED"'
          assert_equal 'UPDATED', @repository.find(1).attributes['title']
        end

        should "delete the object" do
          note = My::Note.new id: 1, title: 'Test'
          @repository.save note

          assert_not_nil @repository.find(1)

          @repository.delete(note)
          assert_raise(Elasticsearch::Persistence::Repository::DocumentNotFound) { @repository.find(1) }
        end

        should "create the index with correct mapping" do
          note = My::Note.new title: 'Testing'
          @repository.save note, refresh: true

          results = @repository.search query: { match: { title: 'Test' } }
          assert_equal 'Testing', results.first.attributes['title']
        end
      end

      context "with a dynamic index name" do
        setup do
          @repository = Elasticsearch::Persistence::Repository.new do
            index { "my-notes-#{Time.now.year}" }
            type  'my_note'
            klass My::Note

            settings number_of_shards: 1 do
              mapping do
                indexes :title, analyzer: 'snowball'
              end
            end

            create_index!
          end

          @repository.client.cluster.health wait_for_status: 'yellow'
        end

        should "save the object under a correct index and type" do
          @repository.save My::Note.new(id: '1', title: 'Test')

          assert_instance_of My::Note, @repository.find(1)
          assert_not_nil Elasticsearch::Persistence.client.get index: "my-notes-#{Time.now.year}", type: 'my_note', id: '1'
        end

        should "update the document" do
          @repository.save Note.new(id: 1, title: 'Test')

          @repository.update 1, doc: { title: 'UPDATED' }
          assert_equal 'UPDATED', @repository.find(1).attributes['title']
        end

        should "update the document with a script" do
          @repository.save Note.new(id: 1, title: 'Test')

          @repository.update 1, script: 'ctx._source.title = "UPDATED"'
          assert_equal 'UPDATED', @repository.find(1).attributes['title']
        end

        should "delete the object" do
          note = My::Note.new id: 1, title: 'Test'
          @repository.save note

          assert_not_nil @repository.find(1)

          @repository.delete(note)
          assert_raise(Elasticsearch::Persistence::Repository::DocumentNotFound) { @repository.find(1) }
        end

        should "create the index with correct mapping" do
          note = My::Note.new title: 'Testing'
          @repository.save note, refresh: true

          results = @repository.search query: { match: { title: 'Test' } }
          assert_equal 'Testing', results.first.attributes['title']
        end
      end

    end
  end
end
