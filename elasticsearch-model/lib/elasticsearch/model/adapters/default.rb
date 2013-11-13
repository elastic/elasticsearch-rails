module Elasticsearch
  module Model
    module Adapter
      module Default

        module Records
          # Use `ActiveModel#find`
          #
          def records
            klass.find(@ids)
          end
        end

        module Callbacks
          # noop
        end

        module Importing
          def __find_in_batches(options={}, &block)
            raise NoMethodError, "Method not implemented for default adapter"
          end
        end

      end
    end
  end
end