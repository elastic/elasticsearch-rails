class Author < ActiveRecord::Base
  has_many :authorships

  after_update { self.authorships.each(&:touch) }

  def full_name
    [first_name, last_name].compact.join(' ')
  end
end
