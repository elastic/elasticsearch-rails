module Elasticsearch
  module Model

    # This module provides the necessary support to set up index options (mappings, settings)
    # as well as instance methods to create, update or delete documents in the index.
    #
    module Indexing

      # Wraps the [index settings](http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/setup-configuration.html#configuration-index-settings)
      #
      class Settings
        attr_accessor :settings

        def initialize(settings={})
          @settings = settings
        end

        def to_hash
          @settings
        end

        def as_json(options={})
          to_hash
        end
      end

      # Wraps the [index mappings](http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/mapping.html)
      #
      class Mappings
        attr_accessor :options

        def initialize(type, options={})
          @type    = type
          @options = options
          @mapping = {}
        end

        def indexes(name, options = {}, &block)
          @mapping[name] = options

          if block_given?
            @mapping[name][:type]       ||= 'object'
            @mapping[name][:properties] ||= {}

            previous = @mapping
            begin
              @mapping = @mapping[name][:properties]
              self.instance_eval(&block)
            ensure
              @mapping = previous
            end
          end

          # Set the `type` to string by default
          #
          @mapping[name][:type] ||= 'string'

          self
        end

        def to_hash
          { @type.to_sym => @options.merge( properties: @mapping ) }
        end

        def as_json(options={})
          to_hash
        end
      end

      module ClassMethods

        # Defines mappings for the index
        #
        # @example Define mapping for model
        #
        #     class Article
        #       mapping dynamic: 'strict' do
        #         indexes :foo do
        #           indexes :bar
        #         end
        #         indexes :baz
        #       end
        #     end
        #
        #     Article.mapping.to_hash
        #
        #     # => { :article =>
        #     #        { :dynamic => "strict",
        #     #          :properties=>
        #     #            { :foo => {
        #     #                :type=>"object",
        #     #                :properties => {
        #     #                  :bar => { :type => "string" }
        #     #                }
        #     #              }
        #     #            },
        #     #           :baz => { :type=> "string" }
        #     #        }
        #     #    }
        #
        # @example Define index settings and mappings
        #
        #     class Article
        #       settings number_of_shards: 1 do
        #         mappings do
        #           indexes :foo
        #         end
        #       end
        #     end
        #
        # @example Call the mapping method directly
        #
        #     Article.mapping(dynamic: 'strict') { indexes :foo, type: 'long' }
        #
        #     Article.mapping.to_hash
        #
        #     # => {:article=>{:dynamic=>"strict", :properties=>{:foo=>{:type=>"long"}}}}
        #
        # The `mappings` and `settings` methods are accessible directly on the model class,
        # when it doesn't already defines them. Use the `__elasticsearch__` proxy otherwise.
        #
        def mapping(options={}, &block)
          @mapping ||= Mappings.new(document_type, options)

          if block_given?
            @mapping.options.update(options)

            @mapping.instance_eval(&block)
            return self
          else
            @mapping
          end
        end; alias_method :mappings, :mapping

        # Define settings for the index
        #
        # @example Define index settings
        #
        #     Article.settings(index: { number_of_shards: 1 })
        #
        #     Article.settings.to_hash
        #
        #     # => {:index=>{:number_of_shards=>1}}
        #
        def settings(settings={}, &block)
          @settings ||= Settings.new(settings)

          @settings.settings.update(settings) unless settings.empty?

          if block_given?
            self.instance_eval(&block)
            return self
          else
            @settings
          end
        end
      end

      module InstanceMethods

        def self.included(base)
          # Register callback for storing changed attributes for models
          # which implement `before_save` and `changed_attributes` methods
          #
          # @note This is typically triggered only when the module would be
          #       included in the model directly, not within the proxy.
          #
          base.before_save do |instance|
            instance_variable_set(:@__changed_attributes,
                                  Hash[ instance.changes.map { |key, value| [key, value.last] } ])
            # puts "--- STORING changes --- (#{self.__elasticsearch__.instance_variable_get(:@__changed_attributes)})"
          end if base.respond_to?(:before_save) && base.instance_methods.include?(:changed_attributes)
        end

        def index_document(options={})
          document = self.as_indexed_json

          client.index(
            { index: index_name,
              type:  document_type,
              id:    self.id,
              body:  document }.merge(options)
          )
        end

        def delete_document(options={})
          client.delete(
            { index: index_name,
              type:  document_type,
              id:    self.id }.merge(options)
          )
        end

        def update_document(options={})
          # puts "--- STORED changes --- (#{self.instance_variable_get(:@__changed_attributes)})"
          if changed_attributes = self.instance_variable_get(:@__changed_attributes)
            client.update(
              { index: index_name,
                type:  document_type,
                id:    self.id,
                body:  { doc: changed_attributes } }.merge(options)
            )
          else
            index_document(options)
          end
        end
      end

    end
  end
end
