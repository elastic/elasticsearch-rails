puts
say_status  "Model", "Adding a `Article.search` class method...\n", :yellow
puts        '-'*80, ''; sleep 0.5


inject_into_file 'app/models/article.rb', <<-CODE, after: 'include Elasticsearch::Model::Callbacks'


  def self.search(query)
    response = __elasticsearch__.search(
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
            content: { fragment_size: 50 }
          }
        }
      }
    )

    response.records
  end
CODE

git :commit => "-a -m 'Added a `Article.search` custom method'"

puts
say_status  "View", "Moving the search form into partial template...\n", :yellow
puts        '-'*80, ''; sleep 0.5

gsub_file 'app/views/articles/index.html.erb', %r{\n<hr>.*<hr>\n}m do |match|
  create_file "app/views/articles/_search_form.html.erb", match
  ''
end

git :add    => 'app/views/articles/index.html.erb app/views/articles/_search_form.html.erb'
git :commit => "-m 'Moved the search form into a partial template'"
