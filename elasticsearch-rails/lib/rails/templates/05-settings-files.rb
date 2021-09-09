# Licensed to Elasticsearch B.V. under one or more contributor
# license agreements. See the NOTICE file distributed with
# this work for additional information regarding copyright
# ownership. Elasticsearch B.V. licenses this file to you under
# the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

#     $ rails new searchapp --skip --skip-bundle --template https://raw.githubusercontent.com/elastic/elasticsearch-rails/main/elasticsearch-rails/lib/rails/templates/05-settings-files.rb

# (See: 01-basic.rb, 02-pretty.rb, 03-expert.rb, 04-dsl.rb)

append_to_file 'README.md', <<-README

## [5] Settings Files

The `settings-files` template refactors the `Searchable` module to load the index settings
from an external file.

README

git add:    "README.md"
git commit: "-m '[05] Updated the application README'"

# ----- Setup the Searchable module to load settings from config/elasticsearch/articles_settings.json

gsub_file "app/models/concerns/searchable.rb",
    /index: { number_of_shards: 1, number_of_replicas: 0 }/,
    "File.open('config/elasticsearch/articles_settings.json')"

git add:    "app/models/concerns/searchable.rb"
git commit: "-m 'Setup the Searchable module to load settings from file'"

# ----- Copy the articles_settings.json file -------------------------------------------------------

# copy_file File.expand_path('../articles_settings.json', __FILE__), 'config/elasticsearch/articles_settings.json'
get 'https://raw.githubusercontent.com/elastic/elasticsearch-rails/main/elasticsearch-rails/lib/rails/templates/articles_settings.json',
    'config/elasticsearch/articles_settings.json', force: true

git add:    "config/elasticsearch/articles_settings.json"
git commit: "-m 'Create the articles settings file'"

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
