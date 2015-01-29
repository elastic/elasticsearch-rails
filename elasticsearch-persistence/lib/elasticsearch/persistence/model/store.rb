module Elasticsearch
  module Persistence
    module Model

      # This module contains the storage related features of {Elasticsearch::Persistence::Model}
      #
      module Store
        module ClassMethods #:nodoc:

          # Creates a class instance, saves it, if validations pass, and returns it
          #
          # @example Create a new person
          #
          #     Person.create name: 'John Smith'
          #     # => #<Person:0x007f889e302b30 ... @id="bG7yQDAXRhCi3ZfVcx6oAA", @name="John Smith" ...>
          #
          # @return [Object] The model instance
          #
          def create(attributes, options={})
            object = self.new(attributes)
            object.run_callbacks :create do
              object.save(options)
              object
            end
          end
        end

        module InstanceMethods

          # Saves the model (if validations pass) and returns the response (or `false`)
          #
          # @example Save a valid model instance
          #
          #     p = Person.new(name: 'John')
          #     p.save
          #     => {"_index"=>"people", ... "_id"=>"RzFSXFR0R8u1CZIWNs2Gvg", "_version"=>1, "created"=>true}
          #
          # @example Save an invalid model instance
          #
          #     p = Person.new(name: nil)
          #     p.save
          #     # => false
          #
          # @return [Hash,FalseClass] The Elasticsearch response as a Hash or `false`
          #
          def save(options={})
            unless options.delete(:validate) == false
              return false unless valid?
            end

            run_callbacks :save do
              options.update id: self.id
              options.update index: self._index if self._index
              options.update type:  self._type  if self._type

              response = self.class.gateway.save(self, options)

              self[:updated_at] = Time.now.utc

              @_id       = response['_id']
              @_index    = response['_index']
              @_type     = response['_type']
              @_version  = response['_version']
              @persisted = true

              response
            end
          end

          # Deletes the model from Elasticsearch (if it's persisted), freezes it, and returns the response
          #
          # @example Delete a model instance
          #
          #     p.destroy
          #     => {"_index"=>"people", ... "_id"=>"RzFSXFR0R8u1CZIWNs2Gvg", "_version"=>2 ...}
          #
          # @return [Hash] The Elasticsearch response as a Hash
          #
          def destroy(options={})
            raise DocumentNotPersisted, "Object not persisted: #{self.inspect}" unless persisted?

            run_callbacks :destroy do
              options.update index: self._index if self._index
              options.update type:  self._type  if self._type

              response = self.class.gateway.delete(self.id, options)

              @destroyed = true
              @persisted = false
              self.freeze
              response
            end
          end; alias :delete :destroy

          # Updates the model (via Elasticsearch's "Update" API) and returns the response
          #
          # @example Update a model with partial attributes
          #
          #     p.update name: 'UPDATED'
          #     => {"_index"=>"people", ... "_version"=>2}
          #
          # @return [Hash] The Elasticsearch response as a Hash
          #
          def update(attributes={}, options={})
            raise DocumentNotPersisted, "Object not persisted: #{self.inspect}" unless persisted?

            run_callbacks :update do
              options.update index: self._index if self._index
              options.update type:  self._type  if self._type

              attributes.update( { updated_at: Time.now.utc } )

              response = self.class.gateway.update(self.id, { doc: attributes}.merge(options))

              self.attributes = self.attributes.merge(attributes)
              @_index    = response['_index']
              @_type     = response['_type']
              @_version  = response['_version']

              response
            end
          end; alias :update_attributes :update

          # Increments a numeric attribute (via Elasticsearch's "Update" API) and returns the response
          #
          # @example Increment the `salary` attribute by 1
          #
          #     p.increment :salary
          #
          # @example Increment the `salary` attribute by 100
          #
          #     p.increment :salary, 100
          #
          # @return [Hash] The Elasticsearch response as a Hash
          #
          def increment(attribute, value=1, options={})
            raise DocumentNotPersisted, "Object not persisted: #{self.inspect}" unless persisted?

            options.update index: self._index if self._index
            options.update type:  self._type  if self._type

            response = self.class.gateway.update(self.id, { script: "ctx._source.#{attribute} += #{value}"}.merge(options))

            self[attribute] += value

            @_index    = response['_index']
            @_type     = response['_type']
            @_version  = response['_version']

            response
          end

          # Decrements a numeric attribute (via Elasticsearch's "Update" API) and returns the response
          #
          # @example Decrement the `salary` attribute by 1
          #
          #     p.decrement :salary
          #
          # @example Decrement the `salary` attribute by 100
          #
          #     p.decrement :salary, 100
          #
          # @return [Hash] The Elasticsearch response as a Hash
          #
          def decrement(attribute, value=1, options={})
            raise DocumentNotPersisted, "Object not persisted: #{self.inspect}" unless persisted?

            options.update index: self._index if self._index
            options.update type:  self._type  if self._type

            response = self.class.gateway.update(self.id, { script: "ctx._source.#{attribute} = ctx._source.#{attribute} - #{value}"}.merge(options))
            self[attribute] -= value

            @_index    = response['_index']
            @_type     = response['_type']
            @_version  = response['_version']

            response
          end

          # Updates the `updated_at` attribute, saves the model and returns the response
          #
          # @example Update the `updated_at` attribute (default)
          #
          #     p.touch
          #
          # @example Update a custom attribute: `saved_on`
          #
          #     p.touch :saved_on
          #
          # @return [Hash] The Elasticsearch response as a Hash
          #
          def touch(attribute=:updated_at, options={})
            raise DocumentNotPersisted, "Object not persisted: #{self.inspect}"  unless persisted?
            raise ArgumentError, "Object does not have '#{attribute}' attribute" unless respond_to?(attribute)

            run_callbacks :touch do
              options.update index: self._index if self._index
              options.update type:  self._type  if self._type

              value = Time.now.utc
              response = self.class.gateway.update(self.id, { doc: { attribute => value.iso8601 }}.merge(options))

              self[attribute] = value

              @_index    = response['_index']
              @_type     = response['_type']
              @_version  = response['_version']

              response
            end
          end

          # Returns true when the model has been destroyed, false otherwise
          #
          # @return [TrueClass,FalseClass]
          #
          def destroyed?
            !!@destroyed
          end

          # Returns true when the model has been already saved to the database, false otherwise
          #
          # @return [TrueClass,FalseClass]
          #
          def persisted?
            !!@persisted && !destroyed?
          end

          # Returns true when the model has not been saved yet, false otherwise
          #
          # @return [TrueClass,FalseClass]
          #
          def new_record?
            !persisted? && !destroyed?
          end
        end
      end

    end
  end
end
