require 'active_support/core_ext/module/delegation'

require 'active_attr'

require 'elasticsearch/persistence'
require 'elasticsearch/persistence/model/base'
require 'elasticsearch/persistence/model/errors'
require 'elasticsearch/persistence/model/store'
require 'elasticsearch/persistence/model/find'
require 'elasticsearch/persistence/model/time_with_zone_typecaster'

module Elasticsearch
  module Persistence

    # When included, extends a plain Ruby class with persistence-related features via the ActiveRecord pattern
    #
    # @example Include the repository in a custom class
    #
    #     require 'elasticsearch/persistence/model'
    #
    #     class MyObject
    #       include Elasticsearch::Persistence::Repository
    #     end
    #
    module Model
      def self.included(base)
        base.class_eval do
          include ActiveAttr::Model

          extend  ActiveModel::Callbacks
          define_model_callbacks :create, :save, :update, :destroy
          define_model_callbacks :find, :touch, only: :after

          include Elasticsearch::Persistence::Model::Base::InstanceMethods

          extend  Elasticsearch::Persistence::Model::Store::ClassMethods
          include Elasticsearch::Persistence::Model::Store::InstanceMethods

          extend  Elasticsearch::Persistence::Model::Find::ClassMethods

          class << self
            # Re-define the active_attr `attribute` method, to configure Elasticsearch mapping as well
            #
            def attribute(name, options={}, &block)
              mapping = options.delete(:mapping) || {}
              super

              gateway.mapping do
                indexes name, {type: Utils::lookup_type(options.fetch(:type, Object))}.merge(mapping)
              end

              gateway.mapping(&block) if block_given?
            end

            # Return the {Repository::Class} instance
            #
            def gateway(&block)
              @gateway ||= Elasticsearch::Persistence::Repository::Class.new host: self
              block.arity < 1 ? @gateway.instance_eval(&block) : block.call(@gateway) if block_given?
              @gateway
            end

            # Delegate methods to repository
            #
            delegate :settings,
                     :mappings,
                     :mapping,
                     :document_type=,
                     :index_name,
                     :index_name=,
                     :find,
                     :exists?,
                     :create_index!,
                     :refresh_index!,
              to: :gateway

            # forward document type to mappings when set
            def document_type(type = nil)
              return gateway.document_type unless type
              gateway.document_type type
              mapping.type = type
            end
          end

          # Configure the repository based on the model (set up index_name, etc)
          #
          gateway do
            klass         base
            index_name    base.model_name.collection.gsub(/\//, '-')
            document_type base.model_name.element

            def serialize(document)
              document.to_hash.except(:id, 'id')
            end

            def deserialize(document)
              object = klass.new document['_source']

              # Set the meta attributes when fetching the document from Elasticsearch
              #
              object.instance_variable_set :@_id,      document['_id']
              object.instance_variable_set :@_index,   document['_index']
              object.instance_variable_set :@_type,    document['_type']
              object.instance_variable_set :@_version, document['_version']
              object.instance_variable_set :@_source,  document['_source']

              # Store the "hit" information (highlighting, score, ...)
              #
              object.instance_variable_set :@hit,
                 Hashie::Mash.new(document.except('_index', '_type', '_id', '_version', '_source'))

              object.instance_variable_set(:@persisted, true)
              object
            end
          end

          # Set up common attributes
          #
          attribute :created_at, type: ActiveSupport::TimeWithZone, default: lambda { Time.now.utc }, typecaster: TimeWithZoneTypecaster.new
          attribute :updated_at, type: ActiveSupport::TimeWithZone, default: lambda { Time.now.utc }, typecaster: TimeWithZoneTypecaster.new

          attr_reader :hit
        end

      end
    end

  end
end
