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

      end
    end
  end
end