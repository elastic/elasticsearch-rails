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
