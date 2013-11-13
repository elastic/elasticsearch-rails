require 'forwardable'

require 'elasticsearch'

require 'hashie'

require 'elasticsearch/model/support/forwardable'

require 'elasticsearch/model/client'

require 'elasticsearch/model/adapter'
require 'elasticsearch/model/adapters/default'
require 'elasticsearch/model/adapters/active_record'
require 'elasticsearch/model/adapters/mongoid'

require 'elasticsearch/model/importing'
require 'elasticsearch/model/indexing'
require 'elasticsearch/model/naming'
require 'elasticsearch/model/serializing'
require 'elasticsearch/model/searching'
require 'elasticsearch/model/callbacks'

require 'elasticsearch/model/proxy'

require 'elasticsearch/model/response'
require 'elasticsearch/model/response/base'
require 'elasticsearch/model/response/result'
require 'elasticsearch/model/response/results'
require 'elasticsearch/model/response/records'

require 'elasticsearch/model/version'

module Elasticsearch

  # Elasticsearch integration for Ruby models
  # =========================================
  #
  # TODO: Description
  #
  module Model

    # Adds the `Elasticsearch::Model` functionality to the including class.
    #
    # * Creates the `__elasticsearch__` class and instance methods, pointing to the proxy object
    # * Includes the necessary modules in the proxy classes
    # * Sets up delegation for crucial methods such as `search`, etc.
    #
    # @example Include the {Elasticsearch::Model} module in the `Article` model definition
    #
    #     class Article < ActiveRecord::Base
    #       include Elasticsearch::Model
    #     end
    #
    # @example Inject the {Elasticsearch::Model} module into the `Article` model
    #
    #     Article.__send__ :include, Elasticsearch::Model
    #
    # It is possible to include/extend the model with the corresponding
    # modules directly, without using the proxy, if this is desired:
    #
    #     MyModel.__send__ :extend,  Elasticsearch::Model::Client::ClassMethods
    #     MyModel.__send__ :include, Elasticsearch::Model::Client::InstanceMethods
    #     MyModel.__send__ :extend,  Elasticsearch::Model::Searching::ClassMethods
    #     # ...
    #
    def self.included(base)
      base.class_eval do
        include Elasticsearch::Model::Proxy

        Elasticsearch::Model::Proxy::ClassMethodsProxy.class_eval do
          include Elasticsearch::Model::Client::ClassMethods
          include Elasticsearch::Model::Naming::ClassMethods
          include Elasticsearch::Model::Indexing::ClassMethods
          include Elasticsearch::Model::Searching::ClassMethods
        end

        Elasticsearch::Model::Proxy::InstanceMethodsProxy.class_eval do
          include Elasticsearch::Model::Client::InstanceMethods
          include Elasticsearch::Model::Naming::InstanceMethods
          include Elasticsearch::Model::Indexing::InstanceMethods
          include Elasticsearch::Model::Serializing::InstanceMethods
        end

        # Delegate important methods to the `__elasticsearch__` proxy, unless they are defined already
        #
        extend  Support::Forwardable
        forward :'self.__elasticsearch__', :search   unless respond_to?(:search)
        forward :'self.__elasticsearch__', :mapping  unless respond_to?(:mapping)
        forward :'self.__elasticsearch__', :settings unless respond_to?(:settings)
        forward :'self.__elasticsearch__', :import   unless respond_to?(:import)

        # Mix the importing module into the proxy
        #
        self.__elasticsearch__.class.__send__ :include, Elasticsearch::Model::Importing::ClassMethods
        self.__elasticsearch__.class.__send__ :include, Adapter.from_class(base).importing_mixin
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
