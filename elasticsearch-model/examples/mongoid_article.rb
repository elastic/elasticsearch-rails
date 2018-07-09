# Mongoid and Elasticsearch
# =========================
#
# http://mongoid.org/en/mongoid/index.html

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'pry'
Pry.config.history.file = File.expand_path('../../tmp/elasticsearch_development.pry', __FILE__)

require 'benchmark'
require 'logger'
require 'ansi/core'
require 'mongoid'

require 'elasticsearch/model'
require 'elasticsearch/model/callbacks'

Mongoid.logger.level = Logger::DEBUG
Moped.logger.level = Logger::DEBUG

Mongoid.connect_to 'articles'

Elasticsearch::Model.client = Elasticsearch::Client.new host: 'localhost:9200', log: true

class Article
  include Mongoid::Document
  field :id, type: String
  field :title, type: String
  field :published_at, type: DateTime
  attr_accessible :id, :title, :published_at if respond_to? :attr_accessible

  def as_indexed_json(options={})
    as_json(except: [:id, :_id])
  end
end

# Extend the model with Elasticsearch support
#
Article.__send__ :include, Elasticsearch::Model
# Article.__send__ :include, Elasticsearch::Model::Callbacks

# Store data
#
Article.delete_all
Article.create id: '1', title: 'Foo'
Article.create id: '2', title: 'Bar'
Article.create id: '3', title: 'Foo Foo'

# Index data
#
client = Elasticsearch::Client.new host:'localhost:9200', log:true

client.indices.delete index: 'articles' rescue nil
client.bulk index: 'articles',
            type:  'article',
            body:  Article.all.map { |a| { index: { _id: a.id, data: a.attributes } } },
            refresh: true

# puts Benchmark.realtime { 9_875.times { |i| Article.create title: "Foo #{i}" } }

puts '', '-'*Pry::Terminal.width!

response = Article.search 'foo';

Pry.start(binding, prompt: lambda { |obj, nest_level, _| '> ' },
                   input: StringIO.new('response.records.to_a'),
                   quiet: true)
