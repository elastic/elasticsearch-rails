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
  return if File.read('app/assets/stylesheets/application.css').include?('.label-highlight')
<<-CODE

.label-highlight {
  font-style: normal !important;
  font-weight: normal !important;
  font-size: 13px !important;
  color: #000 !important;
  background: #fff401;
}
CODE
end

git :commit => "-a -m 'Added custom style definitions into application.css'"
