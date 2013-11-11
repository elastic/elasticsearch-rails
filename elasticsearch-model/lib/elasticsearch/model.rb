require 'forwardable'

require 'elasticsearch'

require 'hashie'

require 'elasticsearch/model/support/forwardable'

require 'elasticsearch/model/client'

require 'elasticsearch/model/adapter'
require 'elasticsearch/model/adapters/default'
require 'elasticsearch/model/adapters/active_record'
require 'elasticsearch/model/adapters/mongoid'

require 'elasticsearch/model/indexing'
require 'elasticsearch/model/naming'
require 'elasticsearch/model/serializing'

require 'elasticsearch/model/response'
require 'elasticsearch/model/response/base'
require 'elasticsearch/model/response/result'
require 'elasticsearch/model/response/results'
require 'elasticsearch/model/response/records'
require 'elasticsearch/model/searching'

require 'elasticsearch/model/version'

module Elasticsearch
  module Model

    # Add the Elasticsearch::Model functionality the including class/module
    #
    def self.included(base)
      base.class_eval do
        extend  Elasticsearch::Model::Client::ClassMethods
        include Elasticsearch::Model::Client::InstanceMethods

        extend  Elasticsearch::Model::Naming::ClassMethods
        include Elasticsearch::Model::Naming::InstanceMethods

        extend  Elasticsearch::Model::Indexing::ClassMethods
        include Elasticsearch::Model::Indexing::InstanceMethods

        include Elasticsearch::Model::Serializing::InstanceMethods

        extend  Elasticsearch::Model::Searching::ClassMethods
      end
    end

    module ClassMethods

      # Get or set the client for all models
      #
      def client client=nil
        @client = client || @client || Elasticsearch::Client.new
      end

    end
    extend ClassMethods

  end
end
