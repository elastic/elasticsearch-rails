require 'test_helper'

require 'elasticsearch/persistence/model'
require 'elasticsearch/persistence/model/rails'

module Elasticsearch
  module Persistence
    class PersistenceModelBasicIntegrationTest < Elasticsearch::Test::IntegrationTestCase

      class ::Person
        include Elasticsearch::Persistence::Model
        include Elasticsearch::Persistence::Model::Rails

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
        setup do
          Person.create_index! force: true
        end

        should "save the object with custom ID" do
          person = Person.new id: 1, name: 'Number One'
          person.save

          document = Person.find(1)
          assert_not_nil document
          assert_equal 'Number One', document.name
        end

        should "create the object with custom ID" do
          person = Person.create id: 1, name: 'Number One'

          document = Person.find(1)
          assert_not_nil document
          assert_equal 'Number One', document.name
        end

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

        should "create the model with correct Date form Rails' form attributes" do
          params = { "birthday(1i)"=>"2014",
                     "birthday(2i)"=>"1",
                     "birthday(3i)"=>"1"
                   }
          person = Person.create params.merge(name: 'TEST')

          assert_equal Date.parse('2014-01-01'), person.birthday
          assert_equal Date.parse('2014-01-01'), Person.find(person.id).birthday
        end

        should_eventually "update the model with correct Date form Rails' form attributes" do
          params = { "birthday(1i)"=>"2014",
                     "birthday(2i)"=>"1",
                     "birthday(3i)"=>"1"
                   }
          person = Person.create params.merge(name: 'TEST')

          person.update params.merge('birthday(1i)' => '2015')

          assert_equal Date.parse('2015-01-01'), person.birthday
          assert_equal Date.parse('2015-01-01'), Person.find(person.id).birthday
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

        should "find all instances" do
          Person.create name: 'John Smith'
          Person.create name: 'Mary Smith'
          Person.gateway.refresh_index!

          people = Person.all

          assert_equal 2, people.total
          assert_equal 2, people.size
        end

        should "find instances by search" do
          Person.create name: 'John Smith'
          Person.create name: 'Mary Smith'
          Person.gateway.refresh_index!

          people = Person.search query: { match: { name: 'smith' } },
                                 highlight: { fields: { name: {} } }

          assert_equal 2, people.total
          assert_equal 2, people.size

          assert people.map_with_hit { |o,h| h._score }.all? { |s| s > 0 }

          assert_not_nil people.first.hit
          assert_match /smith/i, people.first.hit.highlight['name'].first
        end

        should "find instances in batches" do
          50.times { |i| Person.create name: "John #{i+1}" }
          Person.gateway.refresh_index!

          @batches = 0
          @results = []

          Person.find_in_batches(_source_include: 'name') do |batch|
            @batches += 1
            @results += batch.map(&:name)
          end

          assert_equal  3, @batches
          assert_equal 50, @results.size
          assert_contains @results, 'John 1'
        end

        should "find each instance" do
          50.times { |i| Person.create name: "John #{i+1}" }
          Person.gateway.refresh_index!

          @results = []

          Person.find_each(_source_include: 'name') do |person|
            @results << person.name
          end

          assert_equal 50, @results.size
          assert_contains @results, 'John 1'
        end
      end

    end
  end
end
