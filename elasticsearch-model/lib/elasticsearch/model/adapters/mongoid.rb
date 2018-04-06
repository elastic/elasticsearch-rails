module Elasticsearch
  module Model
    module Adapter

      # An adapter for Mongoid-based models
      #
      # @see http://mongoid.org
      #
      module Mongoid

        Adapter.register self,
                         lambda { |klass| !!defined?(::Mongoid::Document) && klass.respond_to?(:ancestors) && klass.ancestors.include?(::Mongoid::Document) }

        module Records

          # Return a `Mongoid::Criteria` instance
          #
          def records
            criteria = klass.where(:id.in => ids)

            criteria.instance_exec(response.response['hits']['hits']) do |hits|
              define_singleton_method :to_a do
                self.entries.sort_by { |e| hits.index { |hit| hit['_id'].to_s == e.id.to_s } }
              end
            end

            criteria
          end

          # Intercept call to sorting methods, so we can ignore the order from Elasticsearch
          #
          %w| asc desc order_by |.each do |name|
            define_method name do |*args|
              criteria = records.__send__ name, *args
              criteria.instance_exec do
                define_singleton_method(:to_a) { self.entries }
              end

              criteria
            end
          end
        end

        module Callbacks

          # Handle index updates (creating, updating or deleting documents)
          # when the model changes, by hooking into the lifecycle
          #
          # @see http://mongoid.org/en/mongoid/docs/callbacks.html
          #
          def self.included(base)
            base.after_create  { |document| document.__elasticsearch__.index_document  }
            base.after_update  { |document| document.__elasticsearch__.update_document }
            base.after_destroy { |document| document.__elasticsearch__.delete_document }
          end
        end

        module Importing

          # Fetch batches of records from the database
          #
          # @see https://github.com/mongoid/mongoid/issues/1334
          # @see https://github.com/karmi/retire/pull/724
          #
          def __find_in_batches(options={}, &block)
            batch_size = options[:batch_size] || 1_000
            query = options[:query]
            named_scope = options[:scope]
            preprocess = options[:preprocess]

            scope = all
            scope = scope.send(named_scope) if named_scope
            scope = query.is_a?(Proc) ? scope.class_exec(&query) : scope.where(query) if query
  
            scope.no_timeout.each_slice(batch_size) do |items|
              yield (preprocess ? self.__send__(preprocess, items) : items)
            end
          end

          def __transform
            lambda {|a|  { index: { _id: a.id.to_s, data: a.as_indexed_json } }}
          end
        end

      end

    end
  end
end
