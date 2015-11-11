module Elasticsearch
  module Model

    # Contains modules and classes for wrapping the response from Elasticsearch
    #
    module Response

      # Encapsulate the response returned from the Elasticsearch client
      #
      # Implements Enumerable and forwards its methods to the {#results} object.
      #
      class Response
        attr_reader :klass, :search, :response,
                    :took, :timed_out, :shards

        include Enumerable

        delegate :each, :empty?, :size, :slice, :[], :to_ary, to: :results

        def self.ensure_pagination_included
          Thread.current[:response_pagination] ||= begin
            case
            when defined?(::Kaminari)
              include(Pagination::Kaminari)
            when defined?(::WillPaginate)
              include(Pagination::WillPaginate)
            end
            true
          end
        end

        def initialize(klass, search, options={})
          self.class.ensure_pagination_included
          @klass     = klass
          @search    = search
        end

        # Returns the Elasticsearch response
        #
        # @return [Hash]
        #
        def response
          @response ||= begin
            Hashie::Mash.new(search.execute!)
          end
        end

        # Returns the collection of "hits" from Elasticsearch
        #
        # @return [Results]
        #
        def results
          @results ||= Results.new(klass, self)
        end

        # Returns the collection of records from the database
        #
        # @return [Records]
        #
        def records
          @records ||= Records.new(klass, self)
        end

        # Returns the "took" time
        #
        def took
          response['took']
        end

        # Returns whether the response timed out
        #
        def timed_out
          response['timed_out']
        end

        # Returns the statistics on shards
        #
        def shards
          Hashie::Mash.new(response['_shards'])
        end

        # Returns a Hashie::Mash of the aggregations
        #
        def aggregations
          response['aggregations'] ? Hashie::Mash.new(response['aggregations']) : nil
        end
      end
    end
  end
end
