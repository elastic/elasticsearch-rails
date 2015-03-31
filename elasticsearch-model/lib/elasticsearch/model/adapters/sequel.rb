module Elasticsearch
  module Model
    module Adapter

      # The default adapter for models which haven't one registered
      #
      module Sequel
        Adapter.register self,
                         lambda { |klass| !!defined?(::Sequel::Model) && klass.ancestors.include?(::Sequel::Model) }

        # Module for implementing methods and logic related to fetching records from the database
        #
        module Records

          # Return the collection of records fetched from the database
          #
          def records
            klass.find(@ids)
          end
        end

        # Module for implementing methods and logic related to hooking into model lifecycle
        # (e.g. to perform automatic index updates)
        module Callbacks

          # Handle index updates (creating, updating or deleting documents)
          # when the model changes, by hooking into the lifecycle
          def self.included(base)
            base.plugin(self)
          end

          module InstanceMethods
            def after_create
              super
              __elasticsearch__.index_document
            end

            def after_update
              super
              __elasticsearch__.update_document
            end

            def after_destroy
              super
              __elasticsearch__.delete_document
            end

            def as_json(opts)
              to_hash
            end
          end
        end

        # Module for efficiently fetching records from the database to import them into the index
        #
        module Importing

          # @abstract Implement this method in your adapter
          #
          def __find_in_batches(options={}, &block)
            rows_per_fetch = options.fetch(:rows_per_fetch, 1_000)

            if respond_to?(:use_cursor)
              target.dataset.use_cursor(options).
                     each_slice(rows_per_fetch, &block)
            else
              items = []

              target.dataset.paged_each(options) do |item|
                items << item
                if items.length % rows_per_fetch == 0
                  yield items
                  items = []
                end
              end

              unless items.empty?
                yield items
              end
            end
          end

          # @abstract Implement this method in your adapter
          #
          def __transform
            lambda {|a| { index: { _id: a.id.to_s, data: a.to_hash } }}
          end
        end
      end
    end
  end
end
