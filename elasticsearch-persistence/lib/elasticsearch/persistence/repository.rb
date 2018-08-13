require 'elasticsearch/persistence/repository/dsl'
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
      end

      module ClassMethods

        # Initialize a repository instance. Optionally provide a block to define index mappings or
        #   settings on the repository instance.
        #
        # @example Create a new repository.
        #   MyRepository.create(index_name: 'notes', klass: Note)
        #
        # @example Create a new repository and evaluate a block on it.
        #   MyRepository.create(index_name: 'notes', klass: Note) do
        #     mapping dynamic: 'strict' do
        #       indexes :title
        #     end
        #   end
        #
        # @param [ Hash ] options The options to use.
        # @param [ Proc ] block A block to evaluate on the new repository instance.
        #
        # @option options [ Symbol, String ] :index_name The name of the index.
        # @option options [ Symbol, String ] :document_type The type of documents persisted in this repository.
        # @option options [ Symbol, String ] :client The client used to handle requests to and from Elasticsearch.
        # @option options [ Symbol, String ] :klass The class used to instantiate an object when documents are
        #   deserialized. The default is nil, in which case the raw document will be returned as a Hash.
        # @option options [ Elasticsearch::Model::Indexing::Mappings, Hash ] :mapping The mapping for this index.
        # @option options [ Elasticsearch::Model::Indexing::Settings, Hash ] :settings The settings for this index.
        #
        # @since 6.0.0
        def create(options = {}, &block)
          new(options).tap do |obj|
            obj.instance_eval(&block) if block_given?
          end
        end
      end

      # The default index name.
      #
      # @return [ String ] The default index name.
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
      #   MyRepository.new(index_name: 'notes', klass: Note)
      #
      # @param [ Hash ] options The options to use.
      #
      # @option options [ Symbol, String ] :index_name The name of the index.
      # @option options [ Symbol, String ] :document_type The type of documents persisted in this repository.
      # @option options [ Symbol, String ] :client The client used to handle requests to and from Elasticsearch.
      # @option options [ Symbol, String ] :klass The class used to instantiate an object when documents are
      #   deserialized. The default is nil, in which case the raw document will be returned as a Hash.
      # @option options [ Elasticsearch::Model::Indexing::Mappings, Hash ] :mapping The mapping for this index.
      # @option options [ Elasticsearch::Model::Indexing::Settings, Hash ] :settings The settings for this index.
      #
      # @since 6.0.0
      def initialize(options = {})
        @options = options
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
        @client ||= @options[:client] ||
                      __get_class_value(:client) ||
                      Elasticsearch::Client.new
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
        @document_type ||= @options[:document_type] ||
                             __get_class_value(:document_type) ||
                             DEFAULT_DOC_TYPE
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
        @index_name ||= @options[:index_name] ||
                          __get_class_value(:index_name) ||
                          DEFAULT_INDEX_NAME
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
        @klass ||= @options[:klass] || __get_class_value(:klass)
      end

      # Get the index mapping. Optionally pass a block to define the mappings.
      #
      # @example
      #   repository.mapping
      #
      # @example Set the mappings with a block.
      #     repository.mapping dynamic: 'strict' do
      #       indexes :foo
      #     end
      #   end
      #
      # @note If mappings were set when the repository was created, a block passed to this
      #   method will not be evaluated.
      #
      # @return [ Elasticsearch::Model::Indexing::Mappings ] The index mappings.
      #
      # @since 6.0.0
      def mapping(*args)
        @memoized_mapping ||= @options[:mapping] || (begin
          if _mapping = __get_class_value(:mapping)
            _mapping.instance_variable_set(:@type, document_type)
            _mapping
          end
        end) || (super && @mapping)
      end
      alias :mappings :mapping

      # Get the index settings.
      #
      # @example
      #   repository.settings
      #
      # @example Set the settings with a block.
      #   repository.settings number_of_shards: 1, number_of_replicas: 0 do
      #     mapping dynamic: 'strict' do
      #       indexes :foo do
      #         indexes :bar
      #       end
      #     end
      #   end
      #
      # @return [ Elasticsearch::Model::Indexing::Settings ] The index settings.
      #
      # @since 6.0.0
      def settings(*args)
        @memoized_settings ||= @options[:settings] || __get_class_value(:settings) || (super && @settings)
      end

      # Determine whether the index with this repository's index name exists.
      #
      # @example
      #   repository.index_exists?
      #
      # @return [ true, false ] Whether the index exists.
      #
      # @since 6.0.0
      def index_exists?(*args)
        super(index_name: index_name)
      end

      # Get the nicer formatted string for use in inspection.
      #
      # @example Inspect the repository.
      #   repository.inspect
      #
      # @return [ String ] The repository inspection.
      #
      # @since 6.0.0
      def inspect
        "#<#{self.class}:0x#{object_id} index_name=#{index_name} document_type=#{document_type} klass=#{klass}>"
      end

      private

      def __get_class_value(_method_)
        self.class.send(_method_) if self.class.respond_to?(_method_)
      end
    end
  end
end
