module Elasticsearch
  module Model
    module Adapter

      # An adapter for Mongoid-based models
      #
      # @see http://mongoid.org
      #
      module Mongoid

        Adapter.register self,
                         lambda { |klass| !!defined?(::Mongoid::Document) && klass.ancestors.include?(::Mongoid::Document) }

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
            options[:batch_size] ||= 1_000
            items = []

            all.each do |item|
              items << item

              if items.length % options[:batch_size] == 0
                yield items
                items = []
              end
            end

            unless items.empty?
              yield items
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
