# =====================================================================================================
# Template for generating a no-frills Rails application with support for Elasticsearch full-text search
# =====================================================================================================
#
# This file creates a basic, fully working Rails application with support for Elasticsearch full-text search
# via the `elasticsearch-rails` gem: https://github.com/elasticsearch/elasticsearch-rails.
#
# Requirements:
# -------------
#
# * Git
# * Ruby  >= 1.9.3
# * Rails >= 4
# * Java  >= 7 (for Elasticsearch)
#
# Usage
# -----
#
#     $ rails new searchapp -m https://github.com/elasticsearch/elasticsearch-rails/blob/master/elasticsearch-rails/lib/rails/templates/basic-application-template.rb
#
# =====================================================================================================

require 'elasticsearch'
client = Elasticsearch::Client.new

at_exit do
  pid = File.read("#{destination_root}/tmp/pids/elasticsearch.pid") rescue nil
  if pid
    say_status  "Stop", "Elasticsearch", :yellow
    run "kill #{pid}"
  end
end

run "touch tmp/.gitignore"

append_to_file ".gitignore", "vendor/elasticsearch-0.90.7/\n"

git :init
git :add => '.'
git :commit => "-m 'Initial commit: Clean application'"

unless (client.ping rescue false)
  COMMAND = <<-COMMAND.gsub(/^    /, '')
    curl -# -O "http://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-0.90.7.tar.gz"
    tar -zxf elasticsearch-0.90.7.tar.gz
    rm  -f   elasticsearch-0.90.7.tar.gz
    ./elasticsearch-0.90.7/bin/elasticsearch -p #{destination_root}/tmp/pids/elasticsearch.pid
  COMMAND

  puts        "\n"
  say_status  "ERROR", "Elasticsearch not running!\n", :red
  puts        '-'*80
  say_status  '',      "It appears that Elasticsearch is not running on this machine."
  say_status  '',      "Is it installed? Do you want me to install it for you with this command?\n\n"
  COMMAND.each_line { |l| say_status '', "$ #{l}" }
  puts
  say_status  '',      "(To uninstall, just remove the generated application directory.)"
  puts        '-'*80, ''

  if yes?("Install Elasticsearch?", :bold)
    puts
    say_status  "Install", "Elasticsearch", :yellow

    commands = COMMAND.split("\n")
    exec     = commands.pop
    inside("vendor") do
      commands.each { |command| run command }
      run "(#{exec})"  # Launch Elasticsearch in subshell
    end
  end
end

begin
  require 'thin'
  puts
  say_status  "Rubygems", "Adding Thin into Gemfile...\n", :yellow
  puts        '-'*80, '';

  gem 'thin'
rescue LoadError
end

puts
say_status  "Rubygems", "Adding Rubygems into Gemfile...\n", :yellow
puts        '-'*80, ''; sleep 0.75

gem 'elasticsearch', :git => 'git@github.com:elasticsearch/elasticsearch-ruby.git'
gem 'elasticsearch-model', :git => 'git@github.com:elasticsearch/elasticsearch-rails.git'
gem 'elasticsearch-rails', :git => 'git@github.com:elasticsearch/elasticsearch-rails.git'

git :add => '.'
git :commit => "-m 'Added gems'"

puts
say_status  "Rubygems", "Installing Rubygems...", :yellow
puts        '-'*80, ''

run "bundle install"

puts
say_status  "Model", "Adding the Article resource...", :yellow
puts        '-'*80, ''; sleep 0.75

generate :scaffold, "Article title:string content:text published_on:date"
route "root :to => 'articles#index'"
rake  "db:migrate"

git :add => '.'
git :commit => "-m 'Added the Article resource'"

puts
say_status  "Database", "Seeding the database with data...", :yellow
puts        '-'*80, ''; sleep 0.25

run "rm -f db/seeds.rb"
file 'db/seeds.rb', %q{
contents = [
'Lorem ipsum dolor sit amet.',
'Consectetur adipisicing elit, sed do eiusmod tempor incididunt.',
'Labore et dolore magna aliqua.',
'Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris.',
'Excepteur sint occaecat cupidatat non proident.'
]

puts "Deleting all articles..."
Article.delete_all

unless ENV['COUNT']

  puts "Creating articles..."
  %w[ One Two Three Four Five ].each_with_index do |title, i|
    Article.create :title => title, :content => contents[i], :published_on => i.days.ago.utc
  end

else

  puts "Creating 10,000 articles..."
  (1..ENV['COUNT'].to_i).each_with_index do |title, i|
    Article.create :title => "Title #{title}", :content => 'Lorem', :published_on => i.days.ago.utc
    print '.'
  end

end
}

rake "db:seed"

git :add    => "db/seeds.rb"
git :commit => "-m 'Added database seeding script'"

puts
say_status  "Model", "Adding search support into the Article model...", :yellow
puts        '-'*80, ''; sleep 0.25

run "rm -f app/models/article.rb"
file 'app/models/article.rb', <<-CODE
class Article < ActiveRecord::Base
  include Elasticsearch::Model
  include Elasticsearch::Model::Callbacks
end
CODE

git :commit => "-a -m 'Added Elasticsearch support into the Article model'"

puts
say_status  "Controller", "Adding controller action, route, and HTML for search...", :yellow
puts        '-'*80, ''; sleep 0.25

gsub_file 'app/controllers/articles_controller.rb', %r{# GET /articles/1$}, <<-CODE
  # GET /articles/search
  def search
    @articles = Article.search(params[:q]).records

    render :action => "index"
  end

  # GET /articles/1
CODE

gsub_file 'app/views/articles/index.html.erb', %r{<h1>Listing articles</h1>}, <<-CODE
<h1>Listing articles</h1>

<hr>

<%= form_tag search_articles_path, :method => 'get' do %>
  <%= label_tag :query %>
  <%= text_field_tag :q, params[:q] %>
  <%= submit_tag :search %>
<% end %>

<hr>
CODE

gsub_file 'app/views/articles/index.html.erb', %r{<%= link_to 'New Article', new_article_path %>}, <<-CODE
<%= link_to 'New Article',  new_article_path %>
<%= link_to 'All articles', articles_path if params[:q] %>
CODE

gsub_file 'config/routes.rb', %r{resources :articles}, <<-CODE
resources :articles do
    collection { get :search }
  end
CODE

git :commit => "-a -m 'Added Elasticsearch support into the frontend of application'"

puts
say_status  "Index", "Indexing the database...", :yellow
puts        '-'*80, ''; sleep 0.25

# rake "environment elasticsearch:import:model CLASS='Article' FORCE=true"
run "rails runner 'Article.__elasticsearch__.client.indices.delete index: Article.__elasticsearch__.index_name rescue nil'"
run "rails runner 'Article.__elasticsearch__.client.indices.create index: Article.__elasticsearch__.index_name'"
run "rails runner 'Article.import'"

puts
say_status  "Git", "Details about the application:", :yellow
puts        '-'*80, ''

run "git log --reverse --pretty=format:'%Cblue%h%Creset | %s'"

if (begin; Elasticsearch::Client.new(host: 'http://localhost:3000'); rescue Errno::ECONNREFUSED; false; rescue Exception; true; end)
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
