module Elasticsearch
  module Model
    module Adapter

      # An adapter for Cequel
      #
      module Cequel
        Adapter.register self, lambda { |klass| !!defined?(::Cequel::Record) && klass.respond_to?(:ancestors) && klass.ancestors.include?(::Cequel::Record) }

        module Records
          # results.records return Enumerable with cequel records
          # Elasticsearch index contains array with all partition and cluster columns values
          #
          # Elasticsearch record's body contains only mapped fields

          def records
            return [] unless ids.present?
            ars = ids.map{|id| JSON.parse(id)}.transpose
            select_options = {}
            ars.each_with_index do |vals, index|
              select_options[klass.columns[index].name] = vals
            end

            klass.where(select_options)
          end
        end

        module Callbacks

          # Handle index updates (creating, updating or deleting documents)
          # when the model changes, by hooking into the lifecycle
          #
          # @see https://github.com/cequel/cequel/blob/master/lib/cequel/record/callbacks.rb
          #

          # Default elasticsearch indexing instance methods overwritten by ProxyMethods
          # with custom index, consisting of partition and cluster column values

          def self.included(base)
            base.include InstanceMethods
            ::Elasticsearch::Model::Indexing::InstanceMethods.prepend ProxyMethods

            [:save, :create, :update].each do |mtd|
              base.send("after_#{ mtd }", lambda { __elasticsearch__.index_document } )
            end
            base.after_destroy { __elasticsearch__.delete_document }
          end

          module InstanceMethods

            def as_indexed_json(options={})
              as_json.map{|k, v| [k, to_supported_type(v)]}.to_h
            end

            private

            def to_supported_type(val)
              if val.is_a?(::Cassandra::TimeUuid) || val.is_a?(::Cassandra::Uuid)
                val.to_s
              else
                val.is_a?(::Cequel::Record::Set) ? val.map(&:to_s) : val
              end
            end
          end

          module ProxyMethods
            def index_document(options={})
              client.index(instance_indexed_hash.merge(options))
            end

            def delete_document(options={})
              client.delete(instance_indexed_hash.except(:body).merge(options))
            end

            def instance_indexed_hash
              index = []
              klass.partition_key_columns.each {|p| index << self[p.name].to_s}
              klass.clustering_columns.each {|c| index << self[c.name].to_s}
              mappings = klass.mappings.to_hash[document_type.to_sym][:properties].keys.map(&:to_s)
              body = self.as_indexed_json.slice(*mappings)

              { id: index, body: body,
                index: index_name, type: document_type }
            end
          end
        end

        module Importing
          def __find_in_batches(options={}, &block)
            raise NotImplemented, "Method not implemented for cequel adapter yet"
          end

          def __transform
            lambda do |model|
              indexed_hash = model.__elasticsearch__.instance_indexed_hash
              { index: { _id: indexed_hash[:id], data: indexed_hash[:body] } }
            end
          end
        end
      end
    end
  end
end
