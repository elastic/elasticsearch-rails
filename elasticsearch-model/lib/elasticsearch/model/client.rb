module Elasticsearch
  module Model

    # Contains an `Elasticsearch::Client` instance
    #
    module Client

      module ClassMethods

        # Get the client for a specific model class
        #
        # @example Get the client for `Article` and perform API request
        #
        #     Article.client.cluster.health
        #     # => { "cluster_name" => "elasticsearch" ... }
        #
        def client client=nil
          @client ||= Elasticsearch::Model.client
        end

        # Set the client for a specific model class
        #
        # @example Configure the client for the `Article` model
        #
        #     Article.client = Elasticsearch::Client.new host: 'http://api.server:8080'
        #     Article.search ...
        #
        def client=(client)
          @client = client
        end
      end

      module InstanceMethods

        # Get or set the client for a specific model instance
        #
        # @example Get the client for a specific record and perform API request
        #
        #     @article = Article.first
        #     @article.client.info
        #     # => { "name" => "Node-1", ... }
        #
        def client
          @client ||= self.class.client
        end

        # Set the client for a specific model instance
        #
        # @example Set the client for a specific record
        #
        #     @article = Article.first
        #     @article.client = Elasticsearch::Client.new host: 'http://api.server:8080'
        #
        def client=(client)
          @client = client
        end
      end

    end
  end
end
