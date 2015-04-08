module Elasticsearch
  module Model
    module Adapter

      # An adapter to be used for deserializing results from multiple models,
      # retrieved through `Elasticsearch::Model.search`
      #
      # @see Elasticsearch::Model.search
      #
      module Multiple
        Adapter.register self, lambda { |klass| klass.is_a? Multimodel }

        module Records
          # Returns a collection of model instances, possibly of different classes (ActiveRecord, Mongoid, ...)
          #
          # @note The order of results in the Elasticsearch response is preserved
          #
          def records
            records_by_type = __records_by_type

            response.response["hits"]["hits"].map do |hit|
              records_by_type[ __type_for_hit(hit) ][ hit[:_id] ]
            end
          end

          # Returns the collection of records grouped by class based on `_type`
          #
          # Example:
          #
          # {
          #   Foo  => {"1"=> #<Foo id: 1, title: "ABC"}, ...},
          #   Bar  => {"1"=> #<Bar id: 1, name: "XYZ"}, ...}
          # }
          #
          # @api private
          #
          def __records_by_type
            result = __ids_by_type.map do |klass, ids|
              records = __records_for_klass(klass, ids)
              ids     = records.map(&:id).map(&:to_s)
              [ klass, Hash[ids.zip(records)] ]
            end

            Hash[result]
          end

          # Returns the collection of records for a specific type based on passed `klass`
          #
          # @api private
          #
          def __records_for_klass(klass, ids)
            adapter = __adapter_name_for_klass(klass)

            case adapter
              when Elasticsearch::Model::Adapter::ActiveRecord
                klass.where(klass.primary_key => ids)
              when Elasticsearch::Model::Adapter::Mongoid
                klass.where(:id.in => ids)
              else
                klass.find(ids)
            end
          end

          # Returns the record IDs grouped by class based on type `_type`
          #
          # Example:
          #
          #   { Foo => ["1"], Bar => ["1", "5"] }
          #
          # @api private
          #
          def __ids_by_type
            ids_by_type = {}

            response.response["hits"]["hits"].each do |hit|
              type = __type_for_hit(hit)
              ids_by_type[type] ||= []
              ids_by_type[type] << hit[:_id]
            end
            ids_by_type
          end

          # Returns the class of the model corresponding to a specific `hit` in Elasticsearch results
          #
          # @see Elasticsearch::Model::Registry
          #
          # @api private
          #
          def __type_for_hit(hit)
            @@__types ||= {}

            @@__types[ "#{hit[:_index]}::#{hit[:_type]}" ] ||= begin
              Registry.all.detect do |model|
                model.index_name == hit[:_index] && model.document_type == hit[:_type]
              end
            end
          end

          # Returns the adapter registered for a particular `klass` or `nil` if not available
          #
          # @api private
          #
          def __adapter_name_for_klass(klass)
            Adapter.adapters.select { |name, checker| checker.call(klass) }.keys.first
          end
        end
      end
    end
  end
end
