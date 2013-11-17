#     $ rails new searchapp --skip --skip-bundle --template https://raw.github.com/elasticsearch/elasticsearch-rails/master/elasticsearch-rails/lib/rails/templates/03-complex.rb

# (See: 01-basic.rb, 02-pretty.rb)

# ----- Move the search form into partial ---------------------------------------------------------

puts
say_status  "View", "Moving the search form into partial template...\n", :yellow
puts        '-'*80, ''; sleep 0.5

gsub_file 'app/views/articles/index.html.erb', %r{\n<hr>.*<hr>\n}m do |match|
  create_file "app/views/articles/_search_form.html.erb", match
  "\n<%= render partial: 'search_form' %>\n"
end

git :add    => 'app/views/articles/index.html.erb app/views/articles/_search_form.html.erb'
git :commit => "-m 'Moved the search form into a partial template'"

# ----- Move the model integration into a concern -------------------------------------------------

puts
say_status  "Model", "Refactoring the model integration...\n", :yellow
puts        '-'*80, ''; sleep 0.5

create_file 'app/models/concerns/searchable.rb', <<-CODE
module Searchable
  extend ActiveSupport::Concern

  included do
    include Elasticsearch::Model
    include Elasticsearch::Model::Callbacks
  end

  module ClassMethods
    def search(query)
      __elasticsearch__.search(
        {
          query: {
            multi_match: {
              query: query,
              fields: ['title^10', 'content']
            }
          },
          highlight: {
            pre_tags: ['<em class="label label-highlight">'],
            post_tags: ['</em>'],
            fields: {
              title:   { number_of_fragments: 0 },
              content: { fragment_size: 25 }
            }
          }
        }
      )
    end
  end
end
CODE

remove_file 'app/models/article.rb'
create_file 'app/models/article.rb', <<-CODE
class Article < ActiveRecord::Base
  include Searchable
end
CODE

git :add    => 'app/models/'
git :commit => "-m 'Refactored the Elasticsearch integration into a concern\n\nSee:\n\n* http://37signals.com/svn/posts/3372-put-chubby-models-on-a-diet-with-concerns\n* http://joshsymonds.com/blog/2012/10/25/rails-concerns-v-searchable-with-elasticsearch/'"

# ----- Add initializer ---------------------------------------------------------------------------

puts
say_status  "Application", "Adding configuration in an initializer...\n", :yellow
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

Elasticsearch::Model.client Elasticsearch::Client.new tracer: tracer, host: ELASTICSEARCH_URL
CODE

git :add    => 'config/initializers'
git :commit => "-m 'Added application initializer with Elasticsearch configuration'"


# ----- Print Git log -----------------------------------------------------------------------------

puts
say_status  "Git", "Details about the application:", :yellow
puts        '-'*80, ''

git :tag => "complex"
git :log => "--reverse --oneline HEAD...pretty"

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
