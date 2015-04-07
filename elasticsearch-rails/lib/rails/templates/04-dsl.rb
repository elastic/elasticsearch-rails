#     $ rails new searchapp --skip --skip-bundle --template https://raw.githubusercontent.com/elastic/elasticsearch-rails/master/elasticsearch-rails/lib/rails/templates/04-dsl.rb

# (See: 01-basic.rb, 02-pretty.rb, 03-expert.rb)

append_to_file 'README.rdoc', <<-README

== [4] DSL

The `dsl` template refactors the search definition in SearchController#index
to use the [`elasticsearch-dsl`](https://github.com/elastic/elasticsearch-ruby/tree/dsl/elasticsearch-dsl)
Rubygem for better expresivity and readability of the code.

README

git add:    "README.rdoc"
git commit: "-m '[03] Updated the application README'"

run 'rm -f app/assets/stylesheets/*.scss'
run 'rm -f app/assets/javascripts/*.coffee'

# ----- Add gems into Gemfile ---------------------------------------------------------------------

puts
say_status  "Rubygems", "Adding Rubygems into Gemfile...\n", :yellow
puts        '-'*80, ''; sleep 0.25

gem "elasticsearch-dsl", git: "git://github.com/elastic/elasticsearch-ruby.git"

git add:    "Gemfile*"
git commit: "-m 'Added the `elasticsearch-dsl` gem'"

# ----- Run bundle install ------------------------------------------------------------------------

run "bundle install"

# ----- Change the search definition implementation and associated views and tests ----------------

# copy_file File.expand_path('../searchable.dsl.rb', __FILE__), 'app/models/concerns/searchable.rb', force: true
get 'https://raw.githubusercontent.com/elastic/elasticsearch-rails/master/elasticsearch-rails/lib/rails/templates/searchable.dsl.rb',
    'app/models/concerns/searchable.rb'

# copy_file File.expand_path('../index.html.dsl.erb', __FILE__), 'app/views/search/index.html.erb', force: true
get 'https://raw.githubusercontent.com/elastic/elasticsearch-rails/master/elasticsearch-rails/lib/rails/templates/index.html.dsl.erb',
    'app/views/search/index.html.erb'

gsub_file "test/controllers/search_controller_test.rb", %r{test "should return facets" do.*?end}m, <<-CODE
test "should return aggregations" do
    get :index, q: 'one'
    assert_response :success

    aggregations = assigns(:articles).response.response['aggregations']

    assert_equal 2, aggregations['categories']['categories']['buckets'].size
    assert_equal 2, aggregations['authors']['authors']['buckets'].size
    assert_equal 2, aggregations['published']['published']['buckets'].size

    assert_equal 'John Smith', aggregations['authors']['authors']['buckets'][0]['key']
    assert_equal 'One', aggregations['categories']['categories']['buckets'][0]['key']
    assert_equal '2015-03-02T00:00:00.000Z', aggregations['published']['published']['buckets'][0]['key_as_string']
  end
CODE

gsub_file "test/controllers/search_controller_test.rb", %r{test "should filter search results and the author and published date facets when user selects a category" do.*?end}m, <<-CODE
test "should filter search results and the author and published date facets when user selects a category" do
    get :index, q: 'one', c: 'One'
    assert_response :success

    assert_equal 2, assigns(:articles).size

    aggregations = assigns(:articles).response.response['aggregations']

    assert_equal 1, aggregations['authors']['authors']['buckets'].size
    assert_equal 1, aggregations['published']['published']['buckets'].size

    # Do NOT filter the category facet
    assert_equal 2, aggregations['categories']['categories']['buckets'].size
  end
CODE

gsub_file "test/controllers/search_controller_test.rb", %r{test "should filter search results and the category and published date facets when user selects a category" do.*?end}m, <<-CODE
test "should filter search results and the category and published date facets when user selects a category" do
    get :index, q: 'one', a: 'Mary Smith'
    assert_response :success

    assert_equal 1, assigns(:articles).size

    aggregations = assigns(:articles).response.response['aggregations']

    assert_equal 1, aggregations['categories']['categories']['buckets'].size
    assert_equal 1, aggregations['published']['published']['buckets'].size

    # Do NOT filter the authors facet
    assert_equal 2, aggregations['authors']['authors']['buckets'].size
  end
CODE

git add:    "app/models/concerns/ app/views/search/ test/controllers/search_controller_test.rb"
git commit: "-m 'Updated the Article.search method to use the Ruby DSL and updated the associated views and tests'"

# ----- Print Git log -----------------------------------------------------------------------------

puts
say_status  "Git", "Details about the application:", :yellow
puts        '-'*80, ''

git tag: "dsl"
git log: "--reverse --oneline HEAD...expert"

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
