module Elasticsearch
  module Model

    # This module provides the support for easily and efficiently importing
    #  all the records from the including class into the index.
    #
    module Importing

      module ClassMethods

        def self.included(base)
          adapter = Adapter.from_class(base)
          base.__send__ :include, adapter.importing_mixin
        end

        # Import all model records into the index
        #
        # The method will pick up correct strategy based on the `Importing` module
        # defined in the corresponding adapter.
        #
        # @example Import all records into the index
        #
        #     Article.import
        #
        # @example Set the batch size to 100
        #
        #     Article.import(batch_size: 100)
        #
        # @example Process the response from Elasticsearch
        #
        #     Article.import do |response|
        #       puts "Got " + response['items'].select { |i| i['index']['error'] }.size.to_s + " errors"
        #     end
        #
        def import(options={}, &block)
          __find_in_batches(options) do |batch|
            response = client.bulk \
                         index: index_name,
                         type:  document_type,
                         body:  batch,
                         refresh: options[:refresh]
            yield response if block_given?
          end
        end

      end

    end

  end
end
