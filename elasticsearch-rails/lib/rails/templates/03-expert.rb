#     $ rails new searchapp --skip --skip-bundle --template https://raw.github.com/elasticsearch/elasticsearch-rails/master/elasticsearch-rails/lib/rails/templates/03-complex.rb

# (See: 01-basic.rb, 02-pretty.rb)

append_to_file 'README.rdoc', <<-README

== [3] Expert

TODO

README

git add:    "README.rdoc"
git commit: "-m 'Updated the application README'"

# ----- Define and generate schema and data -------------------------------------------------------

puts
say_status  "Database", "Adding complex schema and data...\n", :yellow
puts        '-'*80, ''; sleep 0.5

generate :scaffold, "Category title"
generate :scaffold, "Author first_name last_name"
generate :scaffold, "Authorship article:references author:references"

generate :model,     "Comment text:text author:string article:references"
generate :migration, "CreateArticlesCategories article:references category:references"

rake "db:drop"
rake "db:migrate"

insert_into_file "app/models/category.rb", :before => "end" do
  <<-CODE
  has_and_belongs_to_many :articles
  CODE
end

insert_into_file "app/models/author.rb", :before => "end" do
  <<-CODE
  has_many :authorships

  def full_name
    [first_name, last_name].join(' ')
  end
  CODE
end

gsub_file "app/models/authorship.rb", %r{belongs_to :article$}, <<-CODE
belongs_to :article, touch: true
CODE

insert_into_file "app/models/article.rb", :after => "ActiveRecord::Base" do
  <<-CODE

  has_and_belongs_to_many :categories, after_add:    [ lambda { |a,c| a.__elasticsearch__.index_document } ],
                                       after_remove: [ lambda { |a,c| a.__elasticsearch__.index_document } ]
  has_many                :authorships
  has_many                :authors, through: :authorships
  has_many                :comments
  CODE
end

# ----- Move the model integration into a concern -------------------------------------------------

puts
say_status  "Model", "Refactoring the model integration...\n", :yellow
puts        '-'*80, ''; sleep 0.5

remove_file 'app/models/article.rb'
create_file 'app/models/article.rb', <<-CODE
class Article < ActiveRecord::Base
  include Searchable
end
CODE

# TODO
# get "TODO", "app/models/concerns/searchable.rb"

copy_file File.expand_path('../searchable.rb', __FILE__), 'app/models/concerns/searchable.rb'

insert_into_file "app/models/article.rb", :after => "ActiveRecord::Base" do
  <<-CODE

  has_and_belongs_to_many :categories, after_add:    [ lambda { |a,c| a.__elasticsearch__.index_document } ],
                                       after_remove: [ lambda { |a,c| a.__elasticsearch__.index_document } ]
  has_many                :authorships
  has_many                :authors, through: :authorships
  has_many                :comments

  CODE
end

git add:    "app/models/"
git commit: "-m 'Refactored the Elasticsearch integration into a concern\n\nSee:\n\n* http://37signals.com/svn/posts/3372-put-chubby-models-on-a-diet-with-concerns\n* http://joshsymonds.com/blog/2012/10/25/rails-concerns-v-searchable-with-elasticsearch/'"

# ----- Add initializer ---------------------------------------------------------------------------

puts
say_status  "Application", "Adding Elasticsearch configuration in an initializer...\n", :yellow
puts        '-'*80, ''; sleep 0.5

create_file 'config/initializers/elasticsearch.rb', <<-CODE
# Connect to specific Elasticsearch cluster
ELASTICSEARCH_URL = ENV['ELASTICSEARCH_URL'] || 'http://localhost:9200'

# Print Curl-formatted traces in development
#
if Rails.env.development?
  tracer = ActiveSupport::Logger.new(STDERR)
  tracer.level =  Logger::INFO
end

Elasticsearch::Model.client = Elasticsearch::Client.new tracer: tracer, host: ELASTICSEARCH_URL
CODE

git add:    "config/initializers"
git commit: "-m 'Added application initializer with Elasticsearch configuration'"

# ----- Insert and index data ---------------------------------------------------------------------

puts
say_status  "Database", "Seeding the database with data...", :yellow
puts        '-'*80, ''; sleep 0.25

rake "db:seed"

run  "rails runner 'Article.__elasticsearch__.create_index! force: true'"
run  "rails runner 'Article.import'"

# ----- Move the search form into partial ---------------------------------------------------------

puts
say_status  "View", "Moving the search form into partial template...\n", :yellow
puts        '-'*80, ''; sleep 0.5

gsub_file 'app/views/articles/index.html.erb', %r{\n<hr>.*?<hr>\n}m do |match|
  create_file "app/views/articles/_search_form.html.erb", match
  "\n<%= render partial: 'search_form' %>\n"
end

git add:    "app/views/articles/index.html.erb app/views/articles/_search_form.html.erb"
git commit: "-m 'Moved the search form into a partial template'"

# ----- Print Git log -----------------------------------------------------------------------------

puts
say_status  "Git", "Details about the application:", :yellow
puts        '-'*80, ''

git tag: "expert"
git log: "--reverse --oneline HEAD...pretty"

# ----- Start the application ---------------------------------------------------------------------

require 'net/http'
if (begin; Net::HTTP.get(URI('http://localhost:3000')); rescue Errno::ECONNREFUSED; false; rescue Exception; true; end)
  puts        "\n"
  say_status  "ERROR", "Some other application is running on port 3000!\n", :red
  puts        '-'*80

  port = ask("Please provide free port:", :bold)
else
  port = '3000'
end

puts  "", "="*80
say_status  "DONE", "\e[1mStarting the application. Open http://localhost:#{port}\e[0m", :yellow
puts  "="*80, ""

run  "rails server --port=#{port}"
