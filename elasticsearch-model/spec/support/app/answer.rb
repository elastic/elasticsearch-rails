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