module Elasticsearch
  module Persistence
    module Model

      module Store
        module ClassMethods
          def create(attributes, options={})
            object = self.new(attributes)
            object.run_callbacks :create do
              object.save(options)
              object
            end
          end
        end

        module InstanceMethods
          def save(options={})
            return false unless valid?
            run_callbacks :save do
              response = self.class.gateway.save(self, options.merge(id: self.id))
              self[:updated_at] = Time.now.utc
              @persisted = true
              set_id(response['_id']) if respond_to?(:set_id)
              response
            end
          end

          def destroy(options={})
            raise DocumentNotPersisted, "Object not persisted: #{self.inspect}" unless persisted?

            run_callbacks :destroy do
              response = self.class.gateway.delete(self.id, options)
              @destroyed = true
              @persisted = false
              self.freeze
              response
            end
          end; alias :delete :destroy

          def update(attributes={}, options={})
            raise DocumentNotPersisted, "Object not persisted: #{self.inspect}" unless persisted?

            run_callbacks :update do
              attributes.update( { updated_at: Time.now.utc } )
              response = self.class.gateway.update(self.id, { doc: attributes}.merge(options))
              self.attributes = self.attributes.merge(attributes)
              response
            end
          end; alias :update_attributes :update

          def increment(attribute, value=1, options={})
            raise DocumentNotPersisted, "Object not persisted: #{self.inspect}" unless persisted?

            response = self.class.gateway.update(self.id, { script: "ctx._source.#{attribute} += #{value}"}.merge(options))
            self[attribute] += value
            response
          end

          def decrement(attribute, value=1, options={})
            raise DocumentNotPersisted, "Object not persisted: #{self.inspect}" unless persisted?

            response = self.class.gateway.update(self.id, { script: "ctx._source.#{attribute} = ctx._source.#{attribute} - #{value}"}.merge(options))
            self[attribute] -= value
            response
          end

          def touch(attribute=:updated_at, options={})
            raise DocumentNotPersisted, "Object not persisted: #{self.inspect}"  unless persisted?
            raise ArgumentError, "Object does not have '#{attribute}' attribute" unless respond_to?(attribute)

            run_callbacks :touch do
              value = Time.now.utc
              response = self.class.gateway.update(self.id, { doc: { attribute => value.iso8601 }}.merge(options))
              self[attribute] = value
              response
            end
          end

          def destroyed?
            !!@destroyed
          end

          def persisted?
            !!@persisted && !destroyed?
          end

          def new_record?
            !persisted? && !destroyed?
          end
        end
      end

    end
  end
end
