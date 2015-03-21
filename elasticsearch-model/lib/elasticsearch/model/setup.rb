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

        # Get the name of the settings file for a specific model class.
        # Defaults to its document_type.
        #
        # @example Get the settings file name for `Article`
        #
        #     Article.__elasticsearch__.settings_file_name
        #     # => 'article'
        #
        def settings_file_name
          @settings_file_name ||= document_type
        end

        # Set a custom name for the settings file for a specific model class.
        #
        # @example Set `article-customized` as the settings file name for
        # `Article`
        #
        #     Article.__elasticsearch__.settings_file_name = 'article-customized'
        #     Article.__elasticsearch__.settings_file_name
        #     # => 'article-customized'
        #
        def settings_file_name= name
          @settings_file_name = name
        end

        # Searches in all the load paths for a settings file in either
        # json or yml format. Returns the last one found.
        #
        # @example Discover `config/elasticsearch/article.yml`
        #
        #     Article.discover_settings_file
        #
        #     # => 'config/elasticsearch/article.yml
        #
        def discover_settings_file
          paths = load_path.collect {|path| "#{path}/#{settings_file_name}.{yml,json}"}
          Dir.glob(paths).last
        end

        # Load the index settings and mappings from the file found by
        # `discover_settings_file`.
        #
        # @example Load settings from config/elasticsearch/article.yml
        #
        #   # config/elasticsearch/article.yml
        #   #
        #   # settings:
        #   #   foo:
        #   #     "bar"
        #   #
        #
        #   Article.__elasticsearch__.load_settings_from_file!
        #   Article.settings.to_hash
        #   # => {"foo" => "bar"}
        #
        def load_settings_from_file!
          if discover_settings_file
            file = File.open(discover_settings_file)
            settings_from_file = {}
            case File.extname(file.path)
            when ".yml"
              settings_from_file = YAML.load(file.read)
            when ".json"
              settings_from_file = JSON.parse(file.read)
            end
            settings settings_from_file["settings"]
            @mapping = settings_from_file["mappings"]
          end
        end
      end
    end
  end
end

