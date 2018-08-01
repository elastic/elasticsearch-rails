require 'singleton'
require 'elasticsearch/persistence/repository/find'
require 'elasticsearch/persistence/repository/store'
require 'elasticsearch/persistence/repository/serialize'
require 'elasticsearch/persistence/repository/search'

module Elasticsearch
  module Persistence
    module Repository

      # The base repository class. It can be used as it is or other classes can inherit from it
      #   and define their own settings and custom methods.
      #
      # @since 6.0.0
      class Base
        include Singleton
        include Repository::Find
        include Repository::Store
        include Repository::Serialize
        include Repository::Search
        extend Elasticsearch::Model::Indexing::ClassMethods

        class << self

          # Base methods for the class and single instance.
          #
          # @return [ Array<Symbol> ] The base methods.
          #
          # @since 6.0.0
          BASE_METHODS = [ :client,
                           :client=,
                           :index_name,
                           :index_name=,
                           :document_type,
                           :document_type=,
                           :klass,
                           :klass= ].freeze

          # Define each base method explicitly so that #method_missing does not have to be used
          #  each time the method is called.
          #
          BASE_METHODS.each do |_method|
            class_eval("def #{_method}(*args); instance.send(__method__, *args); end", __FILE__, __LINE__)
          end

          # Does the class or the single instance respond to the method.
          #
          # @return [ true, false ] If the class or the instance respond to the method.
          #
          # @since 6.0.0
          def respond_to_missing?(method, include_private = false)
            super || instance.respond_to?(method)
          end

          # Special behavior when a method is called that is not defined on the class.
          #
          # @since 6.0.0
          def method_missing(method, *args)
            instance.send(method, *args)
          end
        end

        # The default index name.
        #
        # @return [ String ] The default repository name.
        #
        # @since 6.0.0
        DEFAULT_INDEX_NAME = 'repository'.freeze

        # The default document type.
        #
        # @return [ String ] The default document type.
        #
        # @note the document type will no longer be configurable in future versions
        #   of Elasticsearch.
        #
        # @since 6.0.0
        DEFAULT_DOC_TYPE = '_doc'.freeze

        # Set or get the client for the repository to use.
        # If the class inherits from another Repository class, the closest ancestor's client
        #   will be returned.
        #
        # @example
        #   repository.client
        #
        # @example
        #   client = Elasticsearch::Client.new
        #   repository.client(client)
        #
        # @param [ Elasticsearch::Client ] _client The client to be used by this repository.
        #
        # @return [ Elasticsearch::Client ] The repository's client.
        #
        # @since 6.0.0
        def client(_client = nil)
          return @client = _client if _client
          return @client if @client

          if self.class.superclass.respond_to?(:client)
            @client = self.class.superclass.send(:client)
          else
            @client ||= Elasticsearch::Client.new
          end
        end

        # Set the client for the repository to use.
        #
        # @example
        #   repository.client = Elasticsearch::Client.new
        #
        # @example
        #   repository.client = nil
        #
        # @param [ Elasticsearch::Client, nil ] _client The client to be used by this repository.
        #   Set it to nil if the repository should fallback to an ancestor's client.
        #
        # @return [ Elasticsearch::Client ] The repository's client.
        #
        # @since 6.0.0
        def client=(_client)
          @client = _client
        end

        # Set or get the index name for the repository.
        # If the class inherits from another Repository class, the closest ancestor's index name
        #   will be returned.
        #
        # @example
        #   repository.index_name
        #
        # @example
        #   repository.index_name('my_repository')
        #
        # @param [ String ] name The name of the index.
        #
        # @return [ String ] The index name.
        #
        # @since 6.0.0
        def index_name(name = nil)
          return @index_name = name if name
          return @index_name if @index_name

          if self.class.superclass.respond_to?(:index_name)
            @index_name = self.class.superclass.send(:index_name)
          else
            @index_name = DEFAULT_INDEX_NAME
          end
        end

        # Set the index name for the repository.
        #
        # @example
        #   repository.index_name = 'my_repository'
        #
        # @example
        #   repository.index_name = nil
        #
        # @param [ String, nil ] name The name of the index. Set to nil if the repository should
        #   fallback to an ancestor's index name.
        #
        # @return [ String ] The index name.
        #
        # @since 6.0.0
        def index_name=(name)
          @index_name = name
        end

        # Set or get the document type for the repository.
        # If the class inherits from another Repository class, the closest ancestor's
        #   document type will be returned.
        #
        # @example
        #   repository.document_type
        #
        # @example
        #   repository.document_type('my_document_type')
        #
        # @note the document type will no longer be configurable in future versions
        #   of Elasticsearch and only one type can be used with a single index with
        #   Elasticsearch versions >= 6.0.
        #
        # @param [ String ] type The document type to use.
        #
        # @return [ String ] The document type.
        #
        # @since 6.0.0
        def document_type(type = nil)
          return @document_type = type if type
          return @document_type if @document_type

          if self.class.superclass.respond_to?(:document_type)
            @document_type = self.class.superclass.send(:document_type)
          else
            @document_type = DEFAULT_DOC_TYPE
          end
        end

        # Set the document type for the repository.
        #
        # @example
        #   repository.document_type = 'my_document_type'
        #
        # @note the document type will no longer be configurable in future versions
        #   of Elasticsearch and only one type can be used with a single index with
        #   Elasticsearch versions >= 6.0.
        #
        # @param [ String, nil ] type The document type to use. Set to nil if the repository should
        #   fallback to an ancestor's document type.
        #
        # @return [ String ] The document type.
        #
        # @since 6.0.0
        def document_type=(type)
          @document_type = type
        end

        # Set or get the class to be used when deserializing documents.
        # If the class inherits from another Repository class, the closest ancestor's
        #   class will be returned. The default is nil.
        #
        # @example
        #   repository.klass
        #
        # @example
        #   repository.klass(Note)
        #
        # @param [ class ] _class The class to use when deserializing documents from Elasticsearch.
        #
        # @return [ class ] The class.
        #
        # @since 6.0.0
        def klass(_class = nil)
          return @klass = _class if _class
          return @klass if @klass

          if self.class.superclass.respond_to?(:klass)
            @klass = self.class.superclass.send(:klass)
          end
        end

        # Set the class to be used when deserializing documents.
        #
        # @example
        #   repository.klass = Note
        #
        # @param [ class ] _class The class to use when deserializing documents from Elasticsearch.
        #
        # @return [ class ] The class.
        #
        # @since 6.0.0
        def klass=(_class)
          @klass = _class
        end

        # Does the class or the single instance respond to the method.
        #
        # @return [ true, false ] If the class or the instance respond to the method.
        #
        # @since 6.0.0
        def respond_to_missing?(method, include_private = false)
          super || self.class.respond_to?(method)
        end

        # Special behavior when a method is called that is not defined on the single instance.
        #
        # @since 6.0.0
        def method_missing(method, *args)
          self.class.send(method, *args)
        end
      end
    end
  end
end
