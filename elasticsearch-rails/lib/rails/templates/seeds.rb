require 'zlib'
require 'yaml'

Zlib::GzipReader.open(File.expand_path('../articles.yml.gz', __FILE__)) do |gzip|
  puts "Reading articles from gzipped YAML..."
  @documents = YAML.load_documents(gzip.read)
end

# Truncate the default ActiveRecord logger output
ActiveRecord::Base.logger = ActiveSupport::Logger.new(STDERR)
ActiveRecord::Base.logger.instance_eval do
  @formatter = lambda do |s, d, p, message|
    message
      .gsub(/\[("content", ".*?")\]/m) { |match| match[0..100] + '..."]' }
      .gsub(/\[("body", ".*?")\]/m   ) { |match| match[0..100] + '..."]' }
      .strip
      .concat("\n")
  end
end

# Reduce verbosity and truncate the request body of Elasticsearch logger
Article.__elasticsearch__.client.transport.tracer.level = Logger::INFO
Article.__elasticsearch__.client.transport.tracer.formatter = lambda do |s, d, p, message|
  "\n\n" + (message.size > 105 ? message[0..105].concat("...}'") : message) + "\n\n"
end

# Skip model callbacks
%w| _touch_callbacks
    _commit_callbacks
    after_add_for_categories
    after_add_for_authorships
    after_add_for_authors
    after_add_for_comments  |.each do |c|
    Article.class.__send__ :define_method, c do; []; end
  end

@documents.each do |document|
  article = Article.create! document.slice(:title, :abstract, :content, :url, :shares, :published_on)

  article.categories = document[:categories].map do |d|
    Category.find_or_create_by! title: d
  end

  article.authors = document[:authors].map do |d|
    first_name, last_name = d.split(' ').compact.map(&:strip)
    Author.find_or_create_by! first_name: first_name, last_name: last_name
  end

  document[:comments].each { |d| article.comments.create! d }

  article.save!
end

# Remove any jobs from the "elasticsearch" Sidekiq queue
#
Sidekiq::Queue.new("elasticsearch").clear
