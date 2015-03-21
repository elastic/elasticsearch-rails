module Elasticsearch
  module Model
    # Provides the necessary support to set up index options (mappings, settings)
    # via configuriation file .yml or .json
    #
    # @see ClassMethods#settings
    # @see ClassMethods#mapping
    #
    # @see InstanceMethods#index_document
    # @see InstanceMethods#update_document
    # @see InstanceMethods#delete_document
    #
    module Setup
      module ClassMethods

        # Get the configuration load path for a specific model class.
        # Defaults to `config/elasticsearch`.
        #
        # @example
        #
        #     Article.__elasticsearch__.load_path
        #     # => ['config/elasticsearch']
        #
        def load_path
          @load_path ||= Array("config/elasticsearch")
        end

        # Set the load path for the discovery of configuration files
        #
        # @example Set the load path to `config/indices` for `Article`
        #
        #     Article.__elasticsearch__.load_path = ['config/indices']
        #
        def load_path= load_path
          @load_path = load_path
        end
      end
    end
  end
end

