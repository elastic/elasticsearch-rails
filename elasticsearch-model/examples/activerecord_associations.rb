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

require 'logger'
require 'ansi/core'
require 'active_record'

require 'json'
require 'elasticsearch/model'

ActiveRecord::Base.logger = ActiveSupport::Logger.new(STDOUT)
ActiveRecord::Base.establish_connection( adapter: 'sqlite3', database: ":memory:" )

# ----- Schema definition -------------------------------------------------------------------------

ActiveRecord::Schema.define(version: 1) do
  create_table :categories do |t|
    t.string     :title
    t.timestamps null: false
  end

  create_table :authors do |t|
    t.string     :first_name, :last_name
    t.timestamps null: false
  end

  create_table :authorships do |t|
    t.references :article
    t.references :author
    t.timestamps null: false
  end

  create_table :articles do |t|
    t.string   :title
    t.timestamps null: false
  end

  create_table :articles_categories, id: false do |t|
    t.references :article, :category
  end

  create_table :comments do |t|
    t.string     :text
    t.references :article
    t.timestamps null: false
  end

  add_index(:comments, :article_id) unless index_exists?(:comments, :article_id)
end

# ----- Elasticsearch client setup ----------------------------------------------------------------

Elasticsearch::Model.client = Elasticsearch::Client.new log: true
Elasticsearch::Model.client.transport.logger.formatter = proc { |s, d, p, m| "\e[2m#{m}\n\e[0m" }

# ----- Search integration ------------------------------------------------------------------------

module Searchable
  extend ActiveSupport::Concern

  included do
    include Elasticsearch::Model
    include Elasticsearch::Model::Callbacks

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

# ----- Model definitions -------------------------------------------------------------------------

class Category < ActiveRecord::Base
  include Elasticsearch::Model
  include Elasticsearch::Model::Callbacks

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
  include Searchable

  has_and_belongs_to_many :categories, after_add:    [ lambda { |a,c| a.__elasticsearch__.index_document } ],
                                       after_remove: [ lambda { |a,c| a.__elasticsearch__.index_document } ]
  has_many                :authorships
  has_many                :authors, through: :authorships
  has_many                :comments
end

class Comment < ActiveRecord::Base
  include Elasticsearch::Model
  include Elasticsearch::Model::Callbacks

  belongs_to :article, touch: true
end

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
article.comments.create text: 'First comment for article One'
article.comments.create text: 'Second comment for article One'

Elasticsearch::Model.client.indices.refresh index: Elasticsearch::Model::Registry.all.map(&:index_name)

# Search for a term and return records
#
puts "",
     "Articles containing 'one':".ansi(:bold),
     Article.search('one').records.to_a.map(&:inspect),
     ""

puts "",
     "All Models containing 'one':".ansi(:bold),
     Elasticsearch::Model.search('one').records.to_a.map(&:inspect),
     ""

# Difference between `records` and `results`
#
response = Article.search query: { match: { title: 'first' } }

puts "",
     "Search results are wrapped in the <#{response.class}> class",
     ""

puts "",
     "Access the <ActiveRecord> instances with the `#records` method:".ansi(:bold),
     response.records.map { |r| "* #{r.title} | Authors: #{r.authors.map(&:full_name) } | Comment count: #{r.comments.size}" }.join("\n"),
     ""

puts "",
     "Access the Elasticsearch documents with the `#results` method (without touching the database):".ansi(:bold),
     response.results.map { |r| "* #{r.title} | Authors: #{r.authors.map(&:full_name) } | Comment count: #{r.comments.size}" }.join("\n"),
     ""

puts "",
     "The indexed document:".ansi(:bold),
     JSON.pretty_generate(response.results.first._source.to_hash),
     ""

# ----- Pry ---------------------------------------------------------------------------------------

Pry.start(binding, prompt: lambda { |obj, nest_level, _| '> ' },
                   input: StringIO.new('response.records.first'),
                   quiet: true)
