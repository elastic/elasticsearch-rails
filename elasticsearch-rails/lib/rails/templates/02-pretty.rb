# $ rails new searchapp --skip --skip-bundle --template https://raw.github.com/elasticsearch/elasticsearch-rails/master/elasticsearch-rails/lib/rails/templates/02-pretty.rb

# (See: 01-basic.rb)

# ----- Add loading Bootstrap assets --------------------------------------------------------------

puts
say_status  "Bootstrap", "Adding Bootstrap asset links into the 'application' layout...\n", :yellow
puts        '-'*80, ''; sleep 0.5

gsub_file 'app/views/layouts/application.html.erb', %r{<%= yield %>}, <<-CODE unless File.read('app/views/layouts/application.html.erb').include?('class="container"')
<div class="container">
<%= yield %>
</div>
CODE

inject_into_file 'app/views/layouts/application.html.erb', <<-CODE, before: '</head>'
  <link rel="stylesheet" href="//netdna.bootstrapcdn.com/bootstrap/3.0.2/css/bootstrap.min.css">
  <script src="//netdna.bootstrapcdn.com/bootstrap/3.0.2/js/bootstrap.min.js"></script>
CODE

git :commit => "-a -m 'Added loading Bootstrap assets in the application layout'"

# ----- Customize the search form -----------------------------------------------------------------

puts
say_status  "Bootstrap", "Customizing the index page...\n", :yellow
puts        '-'*80, ''; sleep 0.5

gsub_file 'app/views/articles/index.html.erb', %r{<%= label_tag .* :search %>}m do |match|
<<-CODE
<div class="input-group">
  <%= text_field_tag :q, params[:q], class: 'form-control', placeholder: 'Search...' %>

  <span class="input-group-btn">
    <button type="button" class="btn btn-default">
      <span class="glyphicon glyphicon-search"></span>
    </button>
  </span>
</div>
CODE
end

git :commit => "-a -m 'Refactored the search form to use Bootstrap components'"

# ----- Customize the results listing -------------------------------------------------------------

gsub_file 'app/views/articles/index.html.erb', %r{<table>} do |match|
  '<table class="table table-hover">'
end

gsub_file 'app/views/articles/index.html.erb', %r{<td><%= link_to [^%]+} do |match|
  match.gsub!('<td>', '<td style="width: 50px">')
  match.include?("btn") ? match : (match << ", class: 'btn btn-default btn-xs'")
end

gsub_file 'app/views/articles/index.html.erb', %r{<%= link_to ('New Article',\s*new_article_path|'All articles',\s*articles_path)} do |match|
  match.include?("btn") ? match : (match += ", class: 'btn btn-primary btn-xs', style: 'color: #fff'")
end

git :commit => "-a -m 'Refactored the articles listing to use Bootstrap components'"

puts
say_status  "CSS", "Adding custom styles...\n", :yellow
puts        '-'*80, ''; sleep 0.5

append_to_file 'app/assets/stylesheets/application.css' do
  unless File.read('app/assets/stylesheets/application.css').include?('.label-highlight')
<<-CODE

.label-highlight {
  font-style: normal !important;
  font-weight: normal !important;
  font-size: 13px !important;
  color: #000 !important;
  background: #fff401;
}
CODE
  else
    ''
  end
end

git :commit => "-a -m 'Added custom style definitions into application.css'"

# ----- Add `Article.search` class method ---------------------------------------------------------

puts
say_status  "Model", "Adding a `Article.search` class method...\n", :yellow
puts        '-'*80, ''; sleep 0.5

inject_into_file 'app/models/article.rb', <<-CODE, after: 'include Elasticsearch::Model::Callbacks'


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

git :add    => 'app/models/article.rb'
git :commit => "-m 'Added a `Article.search` custom method'"

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

git :add    => '.'
git :commit => "-m 'Improved the search results listing'"

# ----- Print Git log -----------------------------------------------------------------------------

puts
say_status  "Git", "Details about the application:", :yellow
puts        '-'*80, ''

git :tag => "pretty"
git :log => "--reverse --oneline pretty...basic"

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
