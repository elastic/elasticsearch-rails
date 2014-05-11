module Elasticsearch
  module Model
    module Adapter

      # The default adapter for models which haven't one registered
      #
      module Default

        # Module for implementing methods and logic related to fetching records from the database
        #
        module Records

          # Return the collection of records fetched from the database
          #
          # By default uses `MyModel#find[1, 2, 3]`
          #
          def records
            klass.find(@ids)
          end
        end

        # Module for implementing methods and logic related to hooking into model lifecycle
        # (e.g. to perform automatic index updates)
        #
        # @see http://api.rubyonrails.org/classes/ActiveModel/Callbacks.html
        module Callbacks
          # noop
        end

        # Module for efficiently fetching records from the database to import them into the index
        #
        module Importing

          # @abstract Implement this method in your adapter
          #
          def __find_in_batches(options={}, &block)
            raise NotImplemented, "Method not implemented for default adapter"
          end

          # @abstract Implement this method in your adapter
          #
          def __transform
            raise NotImplemented, "Method not implemented for default adapter"
          end
        end

      end
    end
  end
end
