# Licensed to Elasticsearch B.V. under one or more contributor
# license agreements. See the NOTICE file distributed with
# this work for additional information regarding copyright
# ownership. Elasticsearch B.V. licenses this file to you under
# the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#	http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

# $ rails new searchapp --skip --skip-bundle --template https://raw.github.com/elasticsearch/elasticsearch-rails/master/elasticsearch-rails/lib/rails/templates/02-pretty.rb

unless File.read('README.md').include? '## [1] Basic'
  say_status  "ERROR", "You have to run the 01-basic.rb template first.", :red
  exit(1)
end

puts
say_status  "README", "Updating Readme...\n", :yellow
puts        '-'*80, ''; sleep 0.25

append_to_file 'README.md', <<-README

## [2] Pretty

The `pretty` template builds on the `basic` version and brings couple of improvements:

* Using the [Bootstrap](http://getbootstrap.com) framework to enhance the visual style of the application
* Using an `Article.search` class method to customize the default search definition
* Highlighting matching phrases in search results
* Paginating results with Kaminari

README

git add:    "README.md"
git commit: "-m '[02] Updated the application README'"

# ----- Update application.rb ---------------------------------------------------------------------

puts
say_status  "Rubygems", "Adding Rails logger integration...\n", :yellow
puts        '-'*80, ''; sleep 0.25

insert_into_file 'config/application.rb',
                 "\n\nrequire 'elasticsearch/rails/instrumentation'",
                 after: /Bundler\.require.+$/

git add:    "config/application.rb"
git commit: "-m 'Added the Rails logger integration to application.rb'"

# ----- Add gems into Gemfile ---------------------------------------------------------------------

puts
say_status  "Rubygems", "Adding Rubygems into Gemfile...\n", :yellow
puts        '-'*80, ''; sleep 0.25

# NOTE: Kaminari has to be loaded before Elasticsearch::Model so the callbacks are executed
#
insert_into_file 'Gemfile', <<-CODE, before: /gem ["']elasticsearch["'].+$/

# NOTE: Kaminari has to be loaded before Elasticsearch::Model so the callbacks are executed
gem 'kaminari'

CODE

run "bundle install"

git add:    "Gemfile*"
git commit: "-m 'Added the Kaminari gem'"

# ----- Add `Article.search` class method ---------------------------------------------------------

puts
say_status  "Model", "Adding a `Article.search` class method...\n", :yellow
puts        '-'*80, ''; sleep 0.5

insert_into_file 'app/models/article.rb', <<-CODE, after: 'include Elasticsearch::Model::Callbacks'


  def self.search(query)
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
CODE

insert_into_file "#{Rails::VERSION::STRING > '4' ? 'test/models' : 'test/unit' }/article_test.rb", <<-CODE, after: /class ArticleTest < ActiveSupport::TestCase$/

  teardown do
    Article.__elasticsearch__.unstub(:search)
  end

CODE

gsub_file "#{Rails::VERSION::STRING > '4' ? 'test/models' : 'test/unit' }/article_test.rb", %r{# test "the truth" do.*?# end}m, <<-CODE

  test "has a search method delegating to __elasticsearch__" do
    Article.__elasticsearch__.expects(:search).with do |definition|
      assert_equal 'foo', definition[:query][:multi_match][:query]
      true
    end

    Article.search 'foo'
  end
CODE

insert_into_file "test/test_helper.rb",
                 "require 'mocha/minitest'\n\n",
                 before: "class ActiveSupport::TestCase\n"

git add:    "app/models/article.rb"
git add:    "test/**/article_test.rb"
git add:    "test/test_helper.rb"
git commit: "-m 'Added an `Article.search` method'"

# ----- Add loading Bootstrap assets --------------------------------------------------------------

puts
say_status  "Bootstrap", "Adding Bootstrap asset links into the 'application' layout...\n", :yellow
puts        '-'*80, ''; sleep 0.5

gsub_file 'app/views/layouts/application.html.erb', %r{<%= yield %>}, <<-CODE unless File.read('app/views/layouts/application.html.erb').include?('class="container"')
<div class="container">
<%= yield %>
</div>
CODE

insert_into_file 'app/views/layouts/application.html.erb', <<-CODE, before: '</head>'
  <link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css">
  <script src="https://code.jquery.com/jquery-3.3.1.slim.min.js"></script>
  <script src="https://stackpath.bootstrapcdn.com/bootstrap/3.3.7/js/bootstrap.min.js"></script>
CODE

git commit: "-a -m 'Added loading Bootstrap assets in the application layout'"

# ----- Customize the search form -----------------------------------------------------------------

puts
say_status  "Bootstrap", "Customizing the index page...\n", :yellow
puts        '-'*80, ''; sleep 0.5

gsub_file 'app/views/articles/index.html.erb', %r{<%= label_tag .* :search %>}m do |match|
<<-CODE
<div class="input-group">
  <%= text_field_tag :q, params[:q], class: 'form-control', placeholder: 'Search...' %>
</div>
CODE
end

# ----- Customize the header -----------------------------------------------------------------

gsub_file 'app/views/articles/index.html.erb', %r{<h1>.*Articles</h1>} do |match|
  "<h1><%= controller.action_name == 'search' ? 'Search results' : 'Articles' %></h1>"
end

# ----- Customize the results listing -------------------------------------------------------------

gsub_file 'app/views/articles/index.html.erb', %r{<table>} do |match|
  '<table class="table table-hover">'
end

gsub_file 'app/views/articles/index.html.erb', %r{<td><%= link_to [^%]+} do |match|
  match.gsub!('<td>', '<td style="width: 50px">')
  match.include?("btn") ? match : (match + ", class: 'btn btn-outline-primary btn-sm'")
end

gsub_file 'app/views/articles/index.html.erb', %r{<br>\s*(<\%= link_to 'New Article'.*)}m do |content|
  replace = content.match(%r{<br>\s*(<\%= link_to 'New Article'.*)}m)[1]
  <<-END.gsub(/^  /, '')
  <hr>

  <p style="text-align: center; margin-bottom: 21px">
    #{replace}
  </p>
  END
end

gsub_file 'app/views/articles/index.html.erb', %r{<%= link_to 'New Article',\s*new_article_path} do |match|
  return match if match.include?('btn')
  match + ", class: 'btn btn-primary btn-xs', style: 'color: #fff'"
end

gsub_file 'app/views/articles/index.html.erb', %r{<%= link_to 'All Articles',\s*articles_path} do |match|
  return match if match.include?('btn')
  "\n  " + match + ", class: 'btn btn-primary btn-xs', style: 'color: #fff'"
end

# ----- Customize the form -----------------------------------------------------------------

gsub_file 'app/views/articles/_form.html.erb', %r{<div class="field">} do |match|
  %Q|<div class="form-group">|
end

git add:    "app/views"
git commit: "-m 'Refactored the articles listing to use Bootstrap components'"

# ----- Use highlighted excerpts in the listing ---------------------------------------------------

gsub_file 'app/views/articles/index.html.erb', %r{<% @articles.each do \|article\| %>$} do |match|
  "<% @articles.__send__ controller.action_name == 'search' ? :each_with_hit : :each do |article, hit| %>"
end

gsub_file 'app/views/articles/index.html.erb', %r{<td><%= article.title %></td>$} do |match|
  "<td><%= hit.try(:highlight).try(:title)   ? hit.highlight.title.join.html_safe : article.title %></td>"
end

gsub_file 'app/views/articles/index.html.erb', %r{<td><%= article.content %></td>$} do |match|
  "<td><%= hit.try(:highlight).try(:content) ? hit.highlight.content.join('&hellip;').html_safe : article.content %></td>"
end

git commit: "-a -m 'Added highlighting for matches'"

# ----- Paginate the results ----------------------------------------------------------------------

gsub_file 'app/controllers/articles_controller.rb', %r{@articles = Article.all} do |match|
  "@articles = Article.page(params[:page])"
end

gsub_file 'app/controllers/articles_controller.rb', %r{@articles = Article.search\(params\[\:q\]\).records} do |match|
  "@articles = Article.search(params[:q]).page(params[:page]).records"
end

insert_into_file 'app/views/articles/index.html.erb', after: '</table>' do
  <<-CODE.gsub(/^  /, '')


  <div class="text-center">
    <%= paginate @articles %>
  </div>
  CODE
end

generate "kaminari:views", "bootstrap3", "--force"

gsub_file 'app/views/kaminari/_paginator.html.erb', %r{<nav>}, '<nav class="pagination">'

git add:    "."
git commit: "-m 'Added pagination to articles listing'"

# ----- Custom CSS --------------------------------------------------------------------------------

puts
say_status  "CSS", "Adding custom styles...\n", :yellow
puts        '-'*80, ''; sleep 0.5

append_to_file 'app/assets/stylesheets/application.css' do
  unless File.read('app/assets/stylesheets/application.css').include?('.label-highlight')
<<-CODE

 body * {
   font-size: 100% !important;
 }

.table {
  border-bottom: 1px solid #dee2e6;
}

.table td {
  vertical-align: middle !important;
}

.label-highlight {
  font-size: 100% !important;
  font-weight: inherit !important;
  font-style: inherit !important;
  color: #333 !important;
  background: #fff401 !important;
  padding: 0.25em 0.5em
  border-radius: 5px;
}

nav.pagination {
  text-align: center;
  display: inline-block;
}

ul.pagination {
  margin-bottom: 0;
}

CODE
  else
    ''
  end
end

git commit: "-a -m 'Added custom style definitions into application.css'"

# ----- Generate 1,000 articles -------------------------------------------------------------------

puts
say_status  "Database", "Creating 1,000 articles...", :yellow
puts        '-'*80, '';

run  "rails runner 'Article.__elasticsearch__.create_index! force: true'"
rake "db:seed COUNT=1_000"

# ----- Print Git log -----------------------------------------------------------------------------

puts
say_status  "Git", "Details about the application:", :yellow
puts        '-'*80, ''

git tag: "pretty"
git log: "--reverse --oneline pretty...basic"

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
