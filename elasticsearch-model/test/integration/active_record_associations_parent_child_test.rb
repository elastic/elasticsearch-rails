require 'test_helper'
require 'active_record'

# Needed for ActiveRecord 3.x ?
ActiveRecord::Base.establish_connection( :adapter => 'sqlite3', :database => ":memory:" ) unless ActiveRecord::Base.connected?

::ActiveRecord::Base.raise_in_transactional_callbacks = true if ::ActiveRecord::Base.respond_to?(:raise_in_transactional_callbacks) && ::ActiveRecord::VERSION::MAJOR.to_s < '5'

class Question < ActiveRecord::Base
  include Elasticsearch::Model

  has_many :answers, dependent: :destroy

  JOIN_TYPE = 'question'.freeze
  JOIN_METADATA = { join_field: JOIN_TYPE}.freeze

  index_name 'questions_and_answers'.freeze
  document_type 'doc'.freeze

  mapping do
    indexes :title
    indexes :text
    indexes :author
  end

  def as_indexed_json(options={})
    # This line is necessary for differences between ActiveModel::Serializers::JSON#as_json versions
    json = as_json(options)[JOIN_TYPE] || as_json(options)
    json.merge(JOIN_METADATA)
  end

  after_commit lambda { __elasticsearch__.index_document  },  on: :create
  after_commit lambda { __elasticsearch__.update_document },  on: :update
  after_commit lambda { __elasticsearch__.delete_document },  on: :destroy
end

class Answer < ActiveRecord::Base
  include Elasticsearch::Model

  belongs_to :question

  JOIN_TYPE = 'answer'.freeze

  index_name 'questions_and_answers'.freeze
  document_type 'doc'.freeze

  before_create :randomize_id

  def randomize_id
    begin
      self.id = SecureRandom.random_number(1_000_000)
    end while Answer.where(id: self.id).exists?
  end

  mapping do
    indexes :text
    indexes :author
  end

  def as_indexed_json(options={})
    # This line is necessary for differences between ActiveModel::Serializers::JSON#as_json versions
    json = as_json(options)[JOIN_TYPE] || as_json(options)
    json.merge(join_field: { name: JOIN_TYPE, parent: question_id })
  end

  after_commit lambda { __elasticsearch__.index_document(routing: (question_id || 1))  },  on: :create
  after_commit lambda { __elasticsearch__.update_document(routing: (question_id || 1)) },  on: :update
  after_commit lambda {__elasticsearch__.delete_document(routing: (question_id || 1)) },  on: :destroy
end

module ParentChildSearchable
  INDEX_NAME = 'questions_and_answers'.freeze
  JOIN = 'join'.freeze

  def create_index!(options={})
    client = Question.__elasticsearch__.client
    client.indices.delete index: INDEX_NAME rescue nil if options[:force]

    settings = Question.settings.to_hash.merge Answer.settings.to_hash
    mapping_properties = { join_field: { type: JOIN,
                                         relations: { Question::JOIN_TYPE => Answer::JOIN_TYPE } } }

    merged_properties = mapping_properties.merge(Question.mappings.to_hash[:doc][:properties]).merge(
        Answer.mappings.to_hash[:doc][:properties])
    mappings = { doc: { properties: merged_properties }}

    client.indices.create index: INDEX_NAME,
                          body: {
                              settings: settings.to_hash,
                              mappings: mappings }
  end

  extend self
end

module Elasticsearch
  module Model
    class ActiveRecordAssociationsParentChildIntegrationTest < Elasticsearch::Test::IntegrationTestCase

      context "ActiveRecord associations with parent/child modelling" do
        setup do
          ActiveRecord::Schema.define(version: 1) do
            create_table :questions do |t|
              t.string     :title
              t.text       :text
              t.string     :author
              t.timestamps null: false
            end

            create_table :answers do |t|
              t.text       :text
              t.string     :author
              t.references :question
              t.timestamps null: false
            end

            add_index(:answers, :question_id) unless index_exists?(:answers, :question_id)
          end

          Question.delete_all
          ParentChildSearchable.create_index! force: true

          q_1 = Question.create! title: 'First Question',  author: 'John'
          q_2 = Question.create! title: 'Second Question', author: 'Jody'

          q_1.answers.create! text: 'Lorem Ipsum', author: 'Adam'
          q_1.answers.create! text: 'Dolor Sit',   author: 'Ryan'

          q_2.answers.create! text: 'Amet Et', author: 'John'

          Question.__elasticsearch__.refresh_index!
        end

        should "find questions by matching answers" do
          response = Question.search(
              { query: {
                  has_child: {
                      type: 'answer',
                      query: {
                          match: {
                              author: 'john'
                          }
                      }
                  }
              }
              })

          assert_equal 'Second Question', response.records.first.title
        end

        should "find answers for matching questions" do
          response = Answer.search(
              { query: {
                  has_parent: {
                      parent_type: 'question',
                      query: {
                          match: {
                              author: 'john'
                          }
                      }
                  }
              }
              })

          assert_same_elements ['Adam', 'Ryan'], response.records.map(&:author)
        end

        should "delete answers when the question is deleted" do
          Question.where(title: 'First Question').each(&:destroy)
          Question.__elasticsearch__.refresh_index!

          response = Answer.search(
              { query: {
                  has_parent: {
                      parent_type: 'question',
                      query: {
                          match_all: {}
                      }
                  }
              }
              })

          assert_equal 1, response.results.total
        end
      end
    end
  end
end
