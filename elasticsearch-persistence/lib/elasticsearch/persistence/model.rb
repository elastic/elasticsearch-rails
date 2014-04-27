require 'active_support/core_ext/module/delegation'

require 'active_model'
require 'virtus'

require 'elasticsearch/persistence'
require 'elasticsearch/persistence/model/errors'
require 'elasticsearch/persistence/model/store'

module Elasticsearch
  module Persistence

    module Model
      module Utils
        def lookup_type(type)
          case
            when type == String
              'string'
            when type == Integer
              'integer'
            when type == Float
              'float'
            when type == Date || type == Time || type == DateTime
              'date'
            when type == Virtus::Attribute::Boolean
              'boolean'
          end
        end; module_function :lookup_type
      end

      def self.included(base)
        base.class_eval do
          include ActiveModel::Naming
          include ActiveModel::Conversion
          include ActiveModel::Serialization
          include ActiveModel::Serializers::JSON
          include ActiveModel::Validations

          include Virtus.model

          extend  ActiveModel::Callbacks
          define_model_callbacks :create, :save, :update, :destroy
          define_model_callbacks :find, :touch, only: :after

          extend  Elasticsearch::Persistence::Model::Store::ClassMethods
          include Elasticsearch::Persistence::Model::Store::InstanceMethods

          class << self
            def attribute(name, type=nil, options={}, &block)
              mapping = options.delete(:mapping) || {}
              super

              gateway.mapping do
                indexes name, {type: Utils::lookup_type(type)}.merge(mapping)
              end

              gateway.mapping(&block) if block_given?
            end

            def gateway(&block)
              @gateway ||= Elasticsearch::Persistence::Repository::Class.new host: self
              block.arity < 1 ? @gateway.instance_eval(&block) : block.call(@gateway) if block_given?
              @gateway
            end

            delegate :settings,
                     :mappings,
                     :mapping,
                     :document_type,
                     :document_type=,
                     :index_name,
                     :index_name=,
                     :search,
                     :find,
                     :exists?,
              to: :gateway
          end

          gateway do
            klass         base
            index_name    base.model_name.collection.gsub(/\//, '-')
            document_type base.model_name.element

            def serialize(document)
              document.to_hash.except(:id, 'id')
            end

            def deserialize(document)
              object = klass.new document['_source']
              object.set_id document['_id']
              object.instance_variable_set(:@persisted, true)
              object
            end
          end

          attribute :id,         String, writer: :private
          attribute :created_at, DateTime, default: lambda { |o,a| Time.now.utc }
          attribute :updated_at, DateTime, default: lambda { |o,a| Time.now.utc }

          def set_id(id)
            self.id = id
          end
        end

      end
    end

  end
end
