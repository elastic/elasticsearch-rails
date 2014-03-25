# ActiveRecord associations and Elasticsearch
# ===========================================
#
# https://github.com/rails/rails/tree/master/activerecord
# http://guides.rubyonrails.org/association_basics.html
#
# Run me with:
#
#     ruby -I lib examples/activerecord_associations.rb
#

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'pry'
Pry.config.history.file = File.expand_path('../../tmp/elasticsearch_development.pry', __FILE__)

require 'logger'
require 'ansi/core'
require 'active_record'

require 'elasticsearch/model'

ActiveRecord::Base.logger = ActiveSupport::Logger.new(STDOUT)
ActiveRecord::Base.establish_connection( adapter: 'sqlite3', database: ":memory:" )

# ----- Schema definition -------------------------------------------------------------------------

ActiveRecord::Schema.define(version: 1) do
  create_table :categories do |t|
    t.string     :title
    t.timestamps
  end

  create_table :authors do |t|
    t.string     :first_name, :last_name
    t.timestamps
  end

  create_table :authorships do |t|
    t.references :article
    t.references :author
    t.timestamps
  end

  create_table :articles do |t|
    t.string   :title
    t.timestamps
  end

  create_table :articles_categories, id: false do |t|
    t.references :article, :category
  end

  create_table :comments do |t|
    t.string     :text
    t.references :article
    t.timestamps
  end
  add_index(:comments, :article_id)
end

# ----- Model definitions -------------------------------------------------------------------------

class Category < ActiveRecord::Base
  has_and_belongs_to_many :articles
end

class Author < ActiveRecord::Base
  has_many :authorships

  after_update { self.authorships.each(&:touch) }

  def full_name
    [first_name, last_name].compact.join(' ')
  end
end

class Authorship < ActiveRecord::Base
  belongs_to :author
  belongs_to :article, touch: true
end

class Article < ActiveRecord::Base
  has_and_belongs_to_many :categories, after_add:    [ lambda { |a,c| a.__elasticsearch__.index_document } ],
                                       after_remove: [ lambda { |a,c| a.__elasticsearch__.index_document } ]
  has_many                :authorships
  has_many                :authors, through: :authorships
  has_many                :comments
end

class Article < ActiveRecord::Base; delegate :size, to: :comments, prefix: true; end

class Comment < ActiveRecord::Base
  belongs_to :article, touch: true
end

# ----- Search integration ------------------------------------------------------------------------

module Searchable
  extend ActiveSupport::Concern

  included do
    include Elasticsearch::Model
    include Elasticsearch::Model::Callbacks

    __elasticsearch__.client = Elasticsearch::Client.new log: true
    __elasticsearch__.client.transport.logger.formatter = proc { |s, d, p, m| "\e[32m#{m}\n\e[0m" }

    include Indexing
    after_touch() { __elasticsearch__.index_document }
  end

  module Indexing

    # Customize the JSON serialization for Elasticsearch
    def as_indexed_json(options={})
      self.as_json(
        include: { categories: { only: :title},
                   authors:    { methods: [:full_name], only: [:full_name] },
                   comments:   { only: :text }
                 })
    end
  end
end

Article.__send__ :include, Searchable

# ----- Insert data -------------------------------------------------------------------------------

# Create category
#
category = Category.create title: 'One'

# Create author
#
author = Author.create first_name: 'John', last_name: 'Smith'

# Create article

article  = Article.create title: 'First Article'

# Assign category
#
article.categories << category

# Assign author
#
article.authors << author

# Add comment
#
article.comments.create text: 'First comment'

# Load
#
article = Article.all.includes(:categories, :authors, :comments).first

# ----- Pry ---------------------------------------------------------------------------------------

Pry.start(binding, prompt: lambda { |obj, nest_level, _| '> ' },
                   input: StringIO.new('puts "\n\narticle.as_indexed_json\n"; article.as_indexed_json'),
                   quiet: true)
