require 'test_helper'

module Elasticsearch
  module Persistence
    class RepositoryCustomClassIntegrationTest < Elasticsearch::Test::IntegrationTestCase

      class ::MyNote
        attr_reader :attributes

        def initialize(attributes={})
          @attributes = Hashie::Mash.new(attributes)
        end

        def method_missing(method_name, *arguments, &block)
          attributes.respond_to?(method_name) ? attributes.__send__(method_name, *arguments, &block) : super
        end

        def respond_to?(method_name, include_private=false)
          attributes.respond_to?(method_name) || super
        end

        def to_hash
          @attributes
        end
      end

      context "A custom repository class" do
        setup do
          class ::MyNotesRepository
            include Elasticsearch::Persistence::Repository

            klass MyNote

            settings number_of_shards: 1 do
              mapping do
                indexes :title, analyzer: 'snowball'
              end
            end

            create_index!

            def deserialize(document)
              klass.new document.merge(document['_source'])
            end
          end

          @repository = MyNotesRepository.new

          @repository.client.cluster.health wait_for_status: 'yellow'
        end

        should "save the object under a correct index and type" do
          @repository.save MyNote.new(id: '1', title: 'Test')
          result = @repository.find(1)

          assert_instance_of MyNote, result
          assert_equal 'Test', result.title

          assert_not_nil Elasticsearch::Persistence.client.get index: 'my_notes_repository',
                                                               type: 'my_note',
                                                               id: '1'
        end

        should "delete the object" do
          note = MyNote.new id: 1, title: 'Test'
          @repository.save note

          assert_not_nil @repository.find(1)

          @repository.delete(note)
          assert_raise(Elasticsearch::Persistence::Repository::DocumentNotFound) { @repository.find(1) }
        end

        should "retrieve the object via a search query" do
          note = MyNote.new title: 'Testing'
          @repository.save note, refresh: true

          results = @repository.search query: { match: { title: 'Test' } }
          assert_equal 'Testing', results.first.title
        end
      end

    end
  end
end
