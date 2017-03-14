# Cequel and Elasticsearch
# ==================================
#
# https://github.com/cequel/cequel

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'pry'
Pry.config.history.file = File.expand_path('/tmp/elasticsearch_development.pry', __FILE__)

require 'benchmark'
require 'logger'

require 'cequel'

require_relative '../lib/elasticsearch/model'
require_relative '../lib/elasticsearch/model/callbacks'

require 'rake'

# Load default tasks from Cequel
#
spec = Gem::Specification.find_by_name 'cequel'
load "#{spec.gem_dir}/lib/cequel/record/tasks.rb"

# Cassandra connection settings
#
cequel_config = {
  host: '127.0.0.1',
  port: 9042,
  keyspace: 'cequel_test',
  max_retries: 3,
  retry_delay: 1,
  replication: {
    class: 'SimpleStrategy',
    replication_factor: 1
  }
}

# Elastic config
#
elastic_config = {
  host: 'localhost:9200',
  log: true
}

connection = Cequel.connect cequel_config
Cequel::Record.connection = connection

Elasticsearch::Model.client = Elasticsearch::Client.new elastic_config


class Article
  include Cequel::Record
  include Elasticsearch::Model
  include Elasticsearch::Model::Callbacks

  key :user_id, :int, partition: true
  key :id, :timeuuid, auto: true

  column :title, :text

  settings index: { number_of_shards: 1 } do
    mappings do
      indexes :title
    end
  end
end

# Initialize Cassandra and synchronize schema
#
Rake.application['cequel:reset'].invoke
Article.synchronize_schema

Article.delete_all

Article.new(user_id: 2, title: 'Foo').save!
Article.new(user_id: 3, title: 'Bar').save!

Article.__elasticsearch__.delete_index!
Article.__elasticsearch__.create_index!

Article.each{|a| a.__elasticsearch__.index_document }

Article.new(user_id: 3, title: 'Foo Bar').save!

puts 'Records count should be eq 2...'
sleep(1)

Pry.start(binding, prompt: lambda { |obj, nest_level, _| '> ' },
                   input: StringIO.new('Article.search("bar").records.to_a.count'),
                   quiet: true)
