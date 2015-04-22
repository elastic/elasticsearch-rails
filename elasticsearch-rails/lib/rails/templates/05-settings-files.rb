#     $ rails new searchapp --skip --skip-bundle --template https://raw.githubusercontent.com/elastic/elasticsearch-rails/master/elasticsearch-rails/lib/rails/templates/05-settings-files.rb

# (See: 01-basic.rb, 02-pretty.rb, 03-expert.rb, 04-dsl.rb)

append_to_file 'README.rdoc', <<-README

== [5] Settings Files

The `settings-files` template refactors the `Searchable` module to load the index settings
from an external file.

README

git add:    "README.rdoc"
git commit: "-m '[05] Updated the application README'"

# ----- Setup the Searchable module to load settings from config/elasticsearch/articles_settings.json

gsub_file "app/models/concerns/searchable.rb",
    /index: { number_of_shards: 1, number_of_replicas: 0 }/,
    "File.open('config/elasticsearch/articles_settings.json')"

git add:    "app/models/concerns/searchable.rb"
git commit: "-m 'Setup the Searchable module to load settings from file'"

# ----- Copy the articles_settings.json file -------------------------------------------------------

copy_file File.expand_path('../articles_settings.json', __FILE__), 'config/elasticsearch/articles_settings.json'

git add:    "config/elasticsearch/articles_settings.json"
git commit: "-m 'Create the articles settings file'"

# ----- Temporarily set local repo for testing ----------------------------------------------------

gsub_file "Gemfile",
    %r{gem 'elasticsearch-model', git: 'git://github.com/elasticsearch/elasticsearch-rails.git'},
    "gem 'elasticsearch-model', path: File.expand_path('../../../../../../elasticsearch-model', __FILE__)"

# ----- Run bundle install ------------------------------------------------------------------------

run "bundle install"

# ----- Recreate the index ------------------------------------------------------------------------

rake "environment elasticsearch:import:model CLASS='Article' BATCH=100 FORCE=y"

# ----- Print Git log -----------------------------------------------------------------------------

puts
say_status  "Git", "Details about the application:", :yellow
puts        '-'*80, ''

git tag: "settings-files"
git log: "--reverse --oneline HEAD...dsl"

# ----- Start the application ---------------------------------------------------------------------

unless ENV['RAILS_NO_SERVER_START']
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
end
