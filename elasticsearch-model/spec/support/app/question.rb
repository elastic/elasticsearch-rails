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
