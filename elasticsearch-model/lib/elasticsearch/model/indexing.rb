module Elasticsearch
  module Model

    # Provides the necessary support to set up index options (mappings, settings)
    # as well as instance methods to create, update or delete documents in the index.
    #
    # @see ClassMethods#settings
    # @see ClassMethods#mapping
    #
    # @see InstanceMethods#index_document
    # @see InstanceMethods#update_document
    # @see InstanceMethods#delete_document
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
          raise ArgumentError, "`type` is missing" if type.nil?

          @type    = type
          @options = options
          @mapping = {}
        end

        def indexes(name, options = {}, &block)
          @mapping[name] = options

          if block_given?
            @mapping[name][:type] ||= 'object'
            properties = @mapping[name][:type] == 'multi_field' ? :fields : :properties

            @mapping[name][properties] ||= {}

            previous = @mapping
            begin
              @mapping = @mapping[name][properties]
              self.instance_eval(&block)
            ensure
              @mapping = previous
            end
          end

          # Set the type to `string` by default
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

        # Creates an index with correct name, automatically passing
        # `settings` and `mappings` defined in the model
        #
        # @example Create an index for the `Article` model
        #
        #     Article.__elasticsearch__.create_index!
        #
        # @example Forcefully create (delete first) an index for the `Article` model
        #
        #     Article.__elasticsearch__.create_index! force: true
        #
        # @example Pass a specific index name
        #
        #     Article.__elasticsearch__.create_index! index: 'my-index'
        #
        def create_index!(options={})
          target_index = options.delete(:index) || self.index_name

          delete_index!(options.merge index: target_index) if options[:force]

          unless ( self.client.indices.exists(index: target_index) rescue false )
            begin
              self.client.indices.create index: target_index,
                                         body: {
                                           settings: self.settings.to_hash,
                                           mappings: self.mappings.to_hash }
            rescue Exception => e
              unless e.class.to_s =~ /NotFound/ && options[:force]
                STDERR.puts "[!!!] Error when creating the index: #{e.class}", "#{e.message}"
              end
            end
          else
          end
        end

        # Deletes the index with corresponding name
        #
        # @example Delete the index for the `Article` model
        #
        #     Article.__elasticsearch__.delete_index!
        #
        # @example Pass a specific index name
        #
        #     Article.__elasticsearch__.delete_index! index: 'my-index'
        #
        def delete_index!(options={})
          target_index = options.delete(:index) || self.index_name

          begin
            self.client.indices.delete index: target_index
          rescue Exception => e
            unless e.class.to_s =~ /NotFound/ && options[:force]
              STDERR.puts "[!!!] Error when deleting the index: #{e.class}", "#{e.message}"
            end
          end
        end

        # Performs the "refresh" operation for the index (useful e.g. in tests)
        #
        # @example Refresh the index for the `Article` model
        #
        #     Article.__elasticsearch__.refresh_index!
        #
        # @example Pass a specific index name
        #
        #     Article.__elasticsearch__.refresh_index! index: 'my-index'
        #
        # @see http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/indices-refresh.html
        #
        def refresh_index!(options={})
          target_index = options.delete(:index) || self.index_name

          begin
            self.client.indices.refresh index: target_index
          rescue Exception => e
            unless e.class.to_s =~ /NotFound/ && options[:force]
              STDERR.puts "[!!!] Error when refreshing the index: #{e.class}", "#{e.message}"
            end
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
          # @see #update_document
          #
          base.before_save do |instance|
            instance.instance_variable_set(:@__changed_attributes,
                                  Hash[ instance.changes.map { |key, value| [key, value.last] } ])
          end if base.respond_to?(:before_save) && base.instance_methods.include?(:changed_attributes)
        end

        # Serializes the model instance into JSON (by calling `as_indexed_json`),
        # and saves the document into the Elasticsearch index.
        #
        # @param options [Hash] Optional arguments for passing to the client
        #
        # @example Index a record
        #
        #     @article.__elasticsearch__.index_document
        #     2013-11-20 16:25:57 +0100: PUT http://localhost:9200/articles/article/1 ...
        #
        # @return [Hash] The response from Elasticsearch
        #
        # @see http://rubydoc.info/gems/elasticsearch-api/Elasticsearch/API/Actions:index
        #
        def index_document(options={})
          document = self.as_indexed_json

          client.index(
            { index: index_name,
              type:  document_type,
              id:    self.id,
              body:  document }.merge(options)
          )
        end

        # Deletes the model instance from the index
        #
        # @param options [Hash] Optional arguments for passing to the client
        #
        # @example Delete a record
        #
        #     @article.__elasticsearch__.delete_document
        #     2013-11-20 16:27:00 +0100: DELETE http://localhost:9200/articles/article/1
        #
        # @return [Hash] The response from Elasticsearch
        #
        # @see http://rubydoc.info/gems/elasticsearch-api/Elasticsearch/API/Actions:delete
        #
        def delete_document(options={})
          client.delete(
            { index: index_name,
              type:  document_type,
              id:    self.id }.merge(options)
          )
        end

        # Tries to gather the changed attributes of a model instance
        # (via [ActiveModel::Dirty](http://api.rubyonrails.org/classes/ActiveModel/Dirty.html)),
        # performing a _partial_ update of the document.
        #
        # When the changed attributes are not available, performs full re-index of the record.
        #
        # @param options [Hash] Optional arguments for passing to the client
        #
        # @example Update a document corresponding to the record
        #
        #     @article = Article.first
        #     @article.update_attribute :title, 'Updated'
        #     # SQL (0.3ms)  UPDATE "articles" SET "title" = ?...
        #
        #     @article.__elasticsearch__.update_document
        #     # 2013-11-20 17:00:05 +0100: POST http://localhost:9200/articles/article/1/_update ...
        #     # 2013-11-20 17:00:05 +0100: > {"doc":{"title":"Updated"}}
        #
        # @return [Hash] The response from Elasticsearch
        #
        # @see http://rubydoc.info/gems/elasticsearch-api/Elasticsearch/API/Actions:update
        #
        def update_document(options={})
          if changed_attributes = self.instance_variable_get(:@__changed_attributes)
            attributes = if respond_to?(:as_indexed_json)
              json = self.as_indexed_json
              changed_attributes.inject({}) do |memo,(key,value)|
                memo[key] = json[key] if json.keys.include? key
                memo
              end
            else
              changed_attributes
            end

            client.update(
              { index: index_name,
                type:  document_type,
                id:    self.id,
                body:  { doc: attributes } }.merge(options)
            )
          else
            index_document(options)
          end
        end
      end

    end
  end
end
