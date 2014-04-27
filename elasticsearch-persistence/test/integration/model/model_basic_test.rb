require 'test_helper'

require 'elasticsearch/persistence/model'

module Elasticsearch
  module Persistence
    class PersistenceModelBasicIntegrationTest < Elasticsearch::Test::IntegrationTestCase

      class ::Person
        include Elasticsearch::Persistence::Model

        settings index: { number_of_shards: 1 }

        attribute :name, String,
                  mapping: { fields: {
                    name: { type: 'string', analyzer: 'snowball' },
                    raw:  { type: 'string', analyzer: 'keyword' }
                  } }

        attribute :birthday,   Date
        attribute :department, String
        attribute :salary,     Integer
        attribute :admin,      Boolean, default: false

        validates :name, presence: true
      end

      context "A basic persistence model" do
        should "save and find the object" do
          person = Person.new name: 'John Smith', birthday: Date.parse('1970-01-01')
          person.save

          assert_not_nil person.id
          document = Person.find(person.id)

          assert_instance_of Person, document
          assert_equal 'John Smith', document.name
          assert_equal 'John Smith', Person.find(person.id).name

          assert_not_nil Elasticsearch::Persistence.client.get index: 'people', type: 'person', id: person.id
        end

        should "delete the object" do
          person = Person.create name: 'John Smith', birthday: Date.parse('1970-01-01')

          person.destroy
          assert person.frozen?

          assert_raise Elasticsearch::Transport::Transport::Errors::NotFound do
            Elasticsearch::Persistence.client.get index: 'people', type: 'person', id: person.id
          end
        end

        should "update an object attribute" do
          person = Person.create name: 'John Smith'

          person.update name: 'UPDATED'

          assert_equal 'UPDATED', person.name
          assert_equal 'UPDATED', Person.find(person.id).name
        end

        should "increment an object attribute" do
          person = Person.create name: 'John Smith', salary: 1_000

          person.increment :salary

          assert_equal 1_001, person.salary
          assert_equal 1_001, Person.find(person.id).salary
        end

        should "update the object timestamp" do
          person = Person.create name: 'John Smith'
          updated_at = person.updated_at

          sleep 1
          person.touch

          assert person.updated_at > updated_at, [person.updated_at, updated_at].inspect

          found = Person.find(person.id)
          assert found.updated_at > updated_at, [found.updated_at, updated_at].inspect
        end

        should "find instances by search" do
          Person.create name: 'John Smith'
          Person.create name: 'Mary Smith'
          Person.gateway.refresh_index!

          people = Person.search query: { match: { name: 'smith' } }

          assert_equal 2, people.total
          assert_equal 2, people.size

          assert people.map_with_hit { |o,h| h._score }.all? { |s| s > 0 }
        end
      end

    end
  end
end
