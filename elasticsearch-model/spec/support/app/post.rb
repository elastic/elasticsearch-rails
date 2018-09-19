class Post < ActiveRecord::Base
  include Searchable

  has_and_belongs_to_many :categories, after_add:    [ lambda { |a,c| a.__elasticsearch__.index_document } ],
                          after_remove: [ lambda { |a,c| a.__elasticsearch__.index_document } ]
  has_many                :authorships
  has_many                :authors, through: :authorships,
                          after_add: [ lambda { |a,c| a.__elasticsearch__.index_document } ],
                          after_remove: [ lambda { |a,c| a.__elasticsearch__.index_document } ]
  has_many                :comments, after_add:    [ lambda { |a,c| a.__elasticsearch__.index_document } ],
                          after_remove: [ lambda { |a,c| a.__elasticsearch__.index_document } ]

  after_touch() { __elasticsearch__.index_document }
end
