module Elasticsearch
  module Model
    module Adapter

      # An adapter for Cequel-based models
      #
      # @see https://github.com/cequel/cequel
      #
      module Cequel

        Adapter.register self, lambda { |klass| !!defined?(::Cequel::Record) && klass.respond_to?(:ancestors) && klass.ancestors.include?(::Cequel::Record) }

        module Records

          # Return a `Cequel::RecordSet` instance
          #
          def records
            pk = klass.key_column_names[0]
            res = klass.where(pk => ids)

            res.instance_exec(response.response['hits']['hits']) do |hits|
              define_singleton_method :to_a do
                self.entries.sort_by do |e|
                  hits.index do |hit|
                    hit['_id'].to_s == e.id.to_s
                  end
                end
              end
            end

            return res
          end
        end

        module Callbacks

          # Handle index updates (creating, updating or deleting documents)
          # when the model changes, by hooking into the lifecycle
          #
          # @see https://github.com/cequel/cequel/blob/master/lib/cequel/record/callbacks.rb
          #
          def self.included(base)
            [:save, :create, :update].each do |item|
              base.send("after_#{ item }", lambda { __elasticsearch__.index_document })
            end

            base.after_destroy { __elasticsearch__.delete_document }
          end
        end

        module Importing
          # Fetch batches of records from the database (used by the import method)
          #
          # @see http://api.rubyonrails.org/classes/ActiveRecord/Batches.html ActiveRecord::Batches.find_in_batches
          #
          def __find_in_batches(options={}, &block)
            query = options.delete(:query)
            named_scope = options.delete(:scope)
            preprocess = options.delete(:preprocess)

            scope = self
            scope = scope.__send__(named_scope) if named_scope
            scope = scope.instance_exec(&query) if query

            scope.find_in_batches(**options) do |batch|
              batch = self.__send__(preprocess, batch) if preprocess
              yield(batch) if batch.present?
            end
          end

          def __transform
            lambda { |model|  { index: { _id: model.id, data: model.__elasticsearch__.as_indexed_json } } }
          end
        end
      end
    end
  end
end
