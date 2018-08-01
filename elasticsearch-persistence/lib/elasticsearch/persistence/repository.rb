require 'elasticsearch/persistence/repository/find'
require 'elasticsearch/persistence/repository/store'
require 'elasticsearch/persistence/repository/serialize'
require 'elasticsearch/persistence/repository/search'

module Elasticsearch
  module Persistence

    # The base Repository mixin. This module should be included in classes that
    # represent an Elasticsearch repository.
    #
    # @since 6.0.0
    module Repository
      include Store
      include Serialize
      include Find
      include Search
      include Elasticsearch::Model::Indexing::ClassMethods

      def self.included(base)
        base.send(:extend, ClassMethods)
        base.send(:extend, Elasticsearch::Model::Indexing::ClassMethods)
      end

      module ClassMethods

        # Get the class-level document type setting.
        #
        # @example
        #   MyRepository.document_type
        #
        # @return [ String, Symbol ] The repository's document type.
        #
        # @since 6.0.0
        def document_type(type = nil)
          @document_type ||= (type || DEFAULT_DOC_TYPE)
        end

        # Get the class-level index name setting.
        #
        # @example
        #   MyRepository.index_name
        #
        # @return [ String, Symbol ] The repository's index name.
        #
        # @since 6.0.0
        def index_name(name = nil)
          @index_name ||= (name || DEFAULT_INDEX_NAME)
        end

        # Get the class-level setting for the class used by the repository when deserializing.
        #
        # @example
        #   MyRepository.klass
        #
        # @return [ Class ] The repository's klass for deserializing.
        #
        # @since 6.0.0
        def klass(_class = nil)
          instance_variables.include?(:@klass) ? @klass : @klass = _class
        end

        def client(client = client)
          @client ||= (client || Elasticsearch::Transport::Client.new)
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

      # The repository options.
      #
      # @return [ Hash ]
      #
      # @since 6.0.0
      attr_reader :options

      # Initialize a repository instance.
      #
      # @example Initialize the repository.
      #   MyRepository.new(options)
      #
      # @param [ Hash ] options The options to use.
      #
      # @option options [ Symbol ] :index_name The name of the index.
      # @option options [ Symbol ] :document_type The type of documents persisted in this repository.
      # @option options [ Symbol ] :client The client used to send and receive requests to and from Elasticsearch.
      # @option options [ Symbol ] :klass The class used to instantiate an object when documents are
      #   deserialized. The default is nil, in which case the raw document will be returned.
      #
      # @since 6.0.0
      def initialize(options = {})
        @options = options
      end

      # Get a new instance of this repository with different options.
      # Any options that are not passed into the method will be kept from the original instance.
      #
      # Provides a new repository object with the passed options merged over the existing
      # options of this repository. Useful for one-offs to change specific options
      # without altering the original repository itself.
      #
      # @example Get a repository with changed options.
      #   repository.with(index_name: 'other_index')
      #
      # @param [ Hash ] new_options The new options to use.
      #
      # @return [ Elasticsearch::Persistence::Repository ] A new repository instance.
      #
      # @since 6.0.0
      def with(new_options = {})
        clone.tap do |repository|
          repository.options.update(new_options)
        end
      end

      # Get the client used by the repository.
      #
      # @example
      #   repository.client
      #
      # @return [ Elasticsearch::Client ] The repository's client.
      #
      # @since 6.0.0
      def client
        @client ||= (@options[:client] || self.class.client)
      end

      # Get the document type used by the repository object.
      #
      # @example
      #   repository.document_type
      #
      # @return [ String, Symbol ] The repository's document type.
      #
      # @since 6.0.0
      def document_type
        @document_type ||= (@options[:document_type] || self.class.document_type)
      end

      # Get the index name used by the repository.
      #
      # @example
      #   repository.index_name
      #
      # @return [ String, Symbol ] The repository's index name.
      #
      # @since 6.0.0
      def index_name
        @index_name ||= (@options[:index_name] || self.class.index_name)
      end

      # Get the class used by the repository when deserializing.
      #
      # @example
      #   repository.klass
      #
      # @return [ Class ] The repository's klass for deserializing.
      #
      # @since 6.0.0
      def klass
        @klass ||= @options[:klass] || self.class.klass
      end

      # Get the index mapping.
      #
      # @example
      #   repository.mapping
      #
      # @return [ Elasticsearch::Model::Indexing::Mappings ] The index mappings.
      #
      # @since 6.0.0
      def mapping
        @mapping ||= (@options[:mapping] || begin
          _mapping = self.class.mapping.dup
          _mapping.instance_variable_set(:@type, document_type)
          _mapping
        end)
      end
      alias :mappings :mapping

      # Get the index settings.
      #
      # @example
      #   repository.settings
      #
      # @return [ Elasticsearch::Model::Indexing::Settings ] The index settings.
      #
      # @since 6.0.0
      def settings
        @settings ||= (@options[:settings] || self.class.settings)
      end

      # Determine whether the index with this repository's index name exists.
      #
      # @example
      #   repository.index_exists?
      #
      # @return [ Hash ] Response from Elasticsearch when determining if an index exists.
      #
      # @since 6.0.0
      def index_exists?(*args)
        super(index_name: index_name)
      end

      private

      def initialize_copy(original)
        @options = original.options.dup
      end
    end
  end
end
