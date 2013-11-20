module Elasticsearch
  module Model

    # Contains an `Elasticsearch::Client` instance
    #
    module Client

      module ClassMethods

        # Get or set the client for a specific model class
        #
        # @example Configure the client for the `Article` model
        #
        #     Article.client Elasticsearch::Client.new host: 'http://api.server:8080'
        #     Article.search ...
        #
        def client client=nil
          @client = client || @client || Elasticsearch::Model.client
        end
      end

      module InstanceMethods

        # Get or set the client for a specific model instance
        #
        # @example Set the client for a specific record
        #
        #     @article = Article.first
        #     @article.client ...
        #
        #
        def client client=nil
          @client = client || @client || self.class.client
        end
      end

    end
  end
end
