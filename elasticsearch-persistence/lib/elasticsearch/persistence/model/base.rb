module Elasticsearch
  module Persistence
    module Model
      # This module contains the base interface for models
      #
      module Base
        module InstanceMethods

          # Model initializer sets the `@id` variable if passed
          #
          def initialize(attributes={})
            @_id = attributes[:id] || attributes['id']
            super
          end

          # Return model attributes as a Hash, merging in the `id`
          #
          def attributes
            super.merge id: id
          end

          # Return the document `_id`
          #
          def id
            @_id
          end; alias :_id :id

          # Return the document `_index`
          #
          def _index
            @_index
          end

          # Return the document `_type`
          #
          def _type
            @_type
          end

          # Return the document `_version`
          #
          def _version
            @_version
          end

          def to_s
            "#<#{self.class} #{attributes.to_hash.inspect.gsub(/:(\w+)=>/, '\1: ')}>"
          end; alias :inspect :to_s
        end
      end

      # Utility methods for {Elasticsearch::Persistence::Model}
      #
      module Utils

        # Return Elasticsearch type based on passed Ruby class (used in the `attribute` method)
        #
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
    end
  end
end
