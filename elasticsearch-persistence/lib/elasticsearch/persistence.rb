require 'elasticsearch'
require 'elasticsearch/model/indexing'
require 'elasticsearch/model/searching'
require 'hashie'

require 'active_support/inflector'

require 'elasticsearch/persistence/version'

require 'elasticsearch/persistence/client'
require 'elasticsearch/persistence/repository/response/results'
require 'elasticsearch/persistence/repository/naming'
require 'elasticsearch/persistence/repository/serialize'
require 'elasticsearch/persistence/repository/store'
require 'elasticsearch/persistence/repository/find'
require 'elasticsearch/persistence/repository/search'
require 'elasticsearch/persistence/repository/class'
require 'elasticsearch/persistence/repository'

module Elasticsearch

  # Persistence for Ruby domain objects and models in Elasticsearch
  # ===============================================================
  #
  # `Elasticsearch::Persistence` contains modules for storing and retrieving Ruby domain objects and models
  # in Elasticsearch.
  #
  # == Repository
  #
  # The repository patterns allows to store and retrieve Ruby objects in Elasticsearch.
  #
  #     require 'elasticsearch/persistence'
  #
  #     class Note
  #       def to_hash; {foo: 'bar'}; end
  #     end
  #
  #     repository = Elasticsearch::Persistence::Repository.new
  #
  #     repository.save Note.new
  #     # => {"_index"=>"repository", "_type"=>"note", "_id"=>"mY108X9mSHajxIy2rzH2CA", ...}
  #
  # Customize your repository by including the main module in a Ruby class
  #     class MyRepository
  #       include Elasticsearch::Persistence::Repository
  #
  #       index 'my_notes'
  #       klass Note
  #
  #       client Elasticsearch::Client.new log: true
  #     end
  #
  #     repository = MyRepository.new
  #
  #     repository.save Note.new
  #     # 2014-04-04 22:15:25 +0200: POST http://localhost:9200/my_notes/note [status:201, request:0.009s, query:n/a]
  #     # 2014-04-04 22:15:25 +0200: > {"foo":"bar"}
  #     # 2014-04-04 22:15:25 +0200: < {"_index":"my_notes","_type":"note","_id":"-d28yXLFSlusnTxb13WIZQ", ...}
  #
  # == Model
  #
  # The active record pattern allows to use the interface familiar from ActiveRecord models:
  #
  #     require 'elasticsearch/persistence'
  #
  #     class Article
  #       attribute :title, String, mapping: { analyzer: 'snowball' }
  #     end
  #
  #     article = Article.new id: 1, title: 'Test'
  #     article.save
  #
  #     Article.find(1)
  #
  #     article.update_attributes title: 'Update'
  #
  #     article.destroy
  #
  module Persistence

    # :nodoc:
    module ClassMethods

      # Get or set the default client for all repositories and models
      #
      # @example Set and configure the default client
      #
      #     Elasticsearch::Persistence.client Elasticsearch::Client.new host: 'http://localhost:9200', tracer: true
      #
      # @example Perform an API request through the client
      #
      #     Elasticsearch::Persistence.client.cluster.health
      #     # => { "cluster_name" => "elasticsearch" ... }
      #
      def client client=nil
        @client = client || @client || Elasticsearch::Client.new
      end

      # Set the default client for all repositories and models
      #
      # @example Set and configure the default client
      #
      #     Elasticsearch::Persistence.client = Elasticsearch::Client.new host: 'http://localhost:9200', tracer: true
      #     => #<Elasticsearch::Transport::Client:0x007f96a6dd0d80 @transport=... >
      #
      def client=(client)
        @client = client
      end
    end

    extend ClassMethods
  end
end
