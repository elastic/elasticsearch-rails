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
require 'elasticsearch/model/response/pagination'

require 'elasticsearch/model/version'

if defined?(::Kaminari)
  Elasticsearch::Model::Response::Response.__send__ :include, Elasticsearch::Model::Response::Pagination::Kaminari
end

module Elasticsearch

  # Elasticsearch integration for Ruby models
  # =========================================
  #
  # `Elasticsearch::Model` contains modules for integrating the Elasticsearch search and analytical engine
  # with ActiveModel-based classes, or models, for the Ruby programming language.
  #
  # It facilitates importing your data into an index, automatically updating it when a record changes,
  # searching the specific index, setting up the index mapping or the model JSON serialization.
  #
  # When the `Elasticsearch::Model` module is included in your class, it automatically extends it
  # with the functionality; see {Elasticsearch::Model.included}. Most methods are available via
  # the `__elasticsearch__` class and instance method proxies.
  #
  # It is possible to include/extend the model with the corresponding
  # modules directly, if that is desired:
  #
  #     MyModel.__send__ :extend,  Elasticsearch::Model::Client::ClassMethods
  #     MyModel.__send__ :include, Elasticsearch::Model::Client::InstanceMethods
  #     MyModel.__send__ :extend,  Elasticsearch::Model::Searching::ClassMethods
  #     # ...
  #
  module Model

    # Adds the `Elasticsearch::Model` functionality to the including class.
    #
    # * Creates the `__elasticsearch__` class and instance methods, pointing to the proxy object
    # * Includes the necessary modules in the proxy classes
    # * Sets up delegation for crucial methods such as `search`, etc.
    #
    # @example Include the module in the `Article` model definition
    #
    #     class Article < ActiveRecord::Base
    #       include Elasticsearch::Model
    #     end
    #
    # @example Inject the module into the `Article` model during run time
    #
    #     Article.__send__ :include, Elasticsearch::Model
    #
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

        Elasticsearch::Model::Proxy::InstanceMethodsProxy.class_eval <<-CODE, __FILE__, __LINE__ + 1
          def as_indexed_json(options={})
            target.respond_to?(:as_indexed_json) ? target.__send__(:as_indexed_json, options) : super
          end
        CODE

        # Delegate important methods to the `__elasticsearch__` proxy, unless they are defined already
        #
        extend  Support::Forwardable
        forward :'self.__elasticsearch__', :search        unless respond_to?(:search)
        forward :'self.__elasticsearch__', :mapping       unless respond_to?(:mapping)
        forward :'self.__elasticsearch__', :mappings      unless respond_to?(:mappings)
        forward :'self.__elasticsearch__', :settings      unless respond_to?(:settings)
        forward :'self.__elasticsearch__', :index_name    unless respond_to?(:index_name)
        forward :'self.__elasticsearch__', :document_type unless respond_to?(:document_type)
        forward :'self.__elasticsearch__', :import        unless respond_to?(:import)

        # Mix the importing module into the proxy
        #
        self.__elasticsearch__.class_eval do
          include Elasticsearch::Model::Importing::ClassMethods
          include Adapter.from_class(base).importing_mixin
        end
      end
    end

    module ClassMethods

      # Get the client common for all models
      #
      # @example Get the client
      #
      #     Elasticsearch::Model.client
      #     => #<Elasticsearch::Transport::Client:0x007f96a7d0d000 @transport=... >
      #
      def client
        @client ||= Elasticsearch::Client.new
      end

      # Set the client for all models
      #
      # @example Configure (set) the client for all models
      #
      #     Elasticsearch::Model.client Elasticsearch::Client.new host: 'http://localhost:9200', tracer: true
      #     => #<Elasticsearch::Transport::Client:0x007f96a6dd0d80 @transport=... >
      #
      # @note You have to set the client before you call Elasticsearch methods on the model,
      #       or set it directly on the model; see {Elasticsearch::Model::Client::ClassMethods#client}
      #
      def client=(client)
        @client = client
      end

    end
    extend ClassMethods

    class NotImplemented < NoMethodError; end
  end
end
