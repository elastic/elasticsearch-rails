module Elasticsearch
  module Model
    module Adapter

      # An adapter to be used for deserializing results from multiple models, retrieved through
      # Elasticsearch::Model.search
      #
      # @see Elasticsearch::Model.search
      #
      module Multiple

        Adapter.register self, lambda { |klass| klass.is_a? Multimodel }

        module Records

          # Returns an Array, which elements are the model instances represented
          # by the search results.
          #
          # This means that if the models queried are a Mixture of ActiveRecord, Mongoid, or
          # POROs, the elements contained in this array will also be instances of those models
          #
          # Ranking of results across multiple indexes is preserved, and queries made to the different
          # model's datasources are minimal.
          #
          # Internally, it gets the results, as ranked by elasticsearch.
          # Then results are grouped by _type
          # Then the model corresponding to each _type is queried to retrieve the records
          # Finally records are rearranged in the same way results were ranked.
          #
          # @return [ElasticSearch::Model]
          #
          def records
            @_records ||= begin
              result = []
              by_type = __records_by_type
              __hits.each do |hit|
                result << by_type[__type(hit)][hit[:_id]]
              end
              result.compact
            end
          end

          # Returns the record representation of the results retrieved from Elasticsearch, grouped
          # by model type
          #
          # @example
          # {Series  =>
          #   {"1"=> #<Series id: 1, series_name: "The Who S01", created_at: "2015-02-23 17:18:28">},
          #
          # "Title =>
          #   {"1"=> #<Title id: 1, name: "Who Strikes Back", created_at: "2015-02-23 17:18:28">}}
          #
          # @api private
          #
          def __records_by_type
            array = __ids_by_type.map do |klass, ids|
              records = __type_records(klass, ids)
              ids = records.map(&:id).map(&:to_s)
              [klass, Hash[ids.zip(records)]]
            end
            Hash[array]
          end

          # Returns the records for a specific type
          #
          # @api private
          #
          def __type_records(klass, ids)
            if (adapter = Adapter.adapters[ActiveRecord]) && adapter.call(klass)
              klass.where(klass.primary_key => ids)
            elsif (adapter = Adapter.adapters[Mongoid]) && adapter.call(klass)
              klass.where(:id.in => ids)
            else
              klass.find(ids)
            end
          end


          # @return A Hash containing for each type, the ids to retrieve
          #
          # @example {Series =>["1"], Title =>["1", "5"]}
          #
          # @api private
          #
          def __ids_by_type
            ids_by_type = {}
            __hits.each do |hit|
              type = __type(hit)
              ids_by_type[type] ||= []
              ids_by_type[type] << hit[:_id]
            end
            ids_by_type
          end

          # Returns the class of the model associated to a certain hit
          #
          # A simple class-level memoization over the `_index` and `_type` properties of the hit is applied.
          # Hence querying the Model Registry is done the minimal amount of times.
          #
          # Event though memoization happens at the class level, the side effect of a race condition will only be
          # to iterate over models one extra time, so we can consider the method thread-safe, and don't include
          # any Mutex.synchronize around the method implementaion
          #
          # @see Elasticsearch::Model::Registry
          #
          # @return Class
          #
          # @api private
          #
          def __type(hit)
            @@__types ||= {}
            @@__types[[hit[:_index], hit[:_type]].join("::")] ||= begin
              Registry.all.detect { |model| model.index_name == hit[:_index] && model.document_type == hit[:_type] }
            end
          end


          # Memoizes and returns the hits from the response
          #
          # @api private
          #
          def __hits
            @__hits ||= response.response["hits"]["hits"]
          end
        end
      end
    end
  end
end
