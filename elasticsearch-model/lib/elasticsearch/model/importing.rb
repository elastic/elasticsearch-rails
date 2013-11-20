module Elasticsearch
  module Model

    # Provides support for easily and efficiently importing large amounts of
    # records from the including class into the index.
    #
    # @see ClassMethods#import
    #
    module Importing

      module ClassMethods

        # When included in a model, adds the importing methods.
        #
        # @example Import all records from the `Article` model
        #
        #     Article.import
        #
        # @see #import
        #
        def self.included(base)
          adapter = Adapter.from_class(base)
          base.__send__ :include, adapter.importing_mixin
        end

        # Import all model records into the index
        #
        # The method will pick up correct strategy based on the `Importing` module
        # defined in the corresponding adapter.
        #
        # @param options [Hash] Options passed to the underlying `__find_in_batches`method
        # @param block  [Proc] Optional block to evaluate for each batch
        #
        # @yield [Hash] Gives the Hash with the Elasticsearch response to the block
        #
        # @return [Fixnum] Number of errors encountered during importing
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
