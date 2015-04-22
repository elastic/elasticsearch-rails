module Elasticsearch
  module Model

    # Keeps a global registry of classes that include `Elasticsearch::Model`
    #
    class Registry
      def initialize
        @models = []
      end

      # Returns the unique instance of the registry (Singleton)
      #
      # @api private
      #
      def self.__instance
        @instance ||= new
      end

      # Adds a model to the registry
      #
      def self.add(klass)
        __instance.add(klass)
      end

      # Returns an Array of registered models
      #
      def self.all
        __instance.models
      end

      # Adds a model to the registry
      #
      def add(klass)
        @models << klass
      end

      # Returns a copy of the registered models
      #
      def models
        @models.dup
      end
    end

    # Wraps a collection of models when querying multiple indices
    #
    # @see Elasticsearch::Model.search
    #
    class Multimodel
      attr_reader :models

      # @param models [Class] The list of models across which the search will be performed
      #
      def initialize(*models)
        @models = models.flatten
        @models = Model::Registry.all if @models.empty?
      end

      # Get an Array of index names used for retrieving documents when doing a search across multiple models
      #
      # @return [Array] the list of index names used for retrieving documents
      #
      def index_name
        models.map { |m| m.index_name }
      end

      # Get an Array of document types used for retrieving documents when doing a search across multiple models
      #
      # @return [Array] the list of document types used for retrieving documents
      #
      def document_type
        models.map { |m| m.document_type }
      end

      # Get the client common for all models
      #
      # @return Elasticsearch::Transport::Client
      #
      def client
        Elasticsearch::Model.client
      end
    end
  end
end
