# Ohm for Redis and Elasticsearch
# ===============================
#
# https://github.com/soveran/ohm#example

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'pry'
Pry.config.history.file = File.expand_path('../../tmp/elasticsearch_development.pry', __FILE__)

require 'logger'
require 'ansi/core'
require 'active_model'
require 'ohm'

require 'elasticsearch/model'

class Article < Ohm::Model
  # Include JSON serialization from ActiveModel
  include ActiveModel::Serializers::JSON

  attribute :title
  attribute :published_at
end

# Extend the model with Elasticsearch support
#
Article.__send__ :include, Elasticsearch::Model

# Register a custom adapter
#
module Elasticsearch
  module Model
    module Adapter
      module Ohm
        Adapter.register self,
                         lambda { |klass| defined?(::Ohm::Model) and klass.ancestors.include?(::Ohm::Model) }
        module Records
          def records
            klass.fetch(@ids)
          end
        end
      end
    end
  end
end

# Configure the Elasticsearch client to log operations
#
Elasticsearch::Model.client = Elasticsearch::Client.new log: true

puts '', '-'*Pry::Terminal.width!

Article.all.map { |a| a.delete }
Article.create id: '1', title: 'Foo'
Article.create id: '2', title: 'Bar'
Article.create id: '3', title: 'Foo Foo'

Article.__elasticsearch__.client.indices.delete index: 'articles' rescue nil
Article.__elasticsearch__.client.bulk index: 'articles',
                                      type:  'article',
                                      body:  Article.all.map { |a| { index: { _id: a.id, data: a.attributes } } },
                                      refresh: true


response = Article.search 'foo', index: 'articles', type: 'article';

Pry.start(binding, prompt: lambda { |obj, nest_level, _| '> ' },
                   input: StringIO.new('response.records.to_a'),
                   quiet: true)
