# Cequel and Elasticsearch
# ==================================
#
# https://github.com/cequel/cequel


$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'pry'
Pry.config.history.file = File.expand_path('/tmp/elasticsearch_development.pry', __FILE__)

require 'benchmark'
require 'logger'

require 'ansi/core'
require 'cequel'

require 'elasticsearch/model'
require 'elasticsearch/model/callbacks'

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

  key :id, :int

  column :title, :text
  column :published_at, :timestamp

  def as_indexed_json(options = {})
    as_json(except: [:id, :_id])
  end
end

Article.__send__ :include, Elasticsearch::Model
Article.__send__ :include, Elasticsearch::Model::Callbacks

# Initialize Cassandra and synchronize schema
#
Rake.application['cequel:reset'].invoke
Article.synchronize_schema

Article.delete_all
Article.new(id: 1, title: 'Foo').save!
Article.new(id: 2, title: 'Bar').save!

client = Elasticsearch::Client.new elastic_config

client.indices.delete index: 'articles' rescue nil


client.bulk index: 'articles',
            type:  'article',
            body:  Article.all.map { |a| { index: { _id: a.id, data: a.attributes } } },
            refresh: true

Article.new(id: 3, title: 'Foo Bar').save!

response = Article.search 'bar'
#x = response.records
#puts x.class
#puts x.to_a.to_s


#puts x.records.where({ :id => [3] })

# puts Benchmark.realtime { 9_875.times { |i| Article.new( id: i, title: "Foo #{i}").save! } }

Pry.start(binding, prompt: lambda { |obj, nest_level, _| '> ' },
                   input: StringIO.new('response.records.to_a'),
                   quiet: true)
