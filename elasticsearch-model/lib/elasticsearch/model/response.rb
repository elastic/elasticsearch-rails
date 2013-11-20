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
        attr_reader :klass, :response

        include Enumerable
        extend  Support::Forwardable

        forward :results, :each, :empty?, :size, :slice, :[], :to_ary

        def initialize(klass, response)
          @klass    = klass
          @response = response
        end

        # Return the collection of "hits" from Elasticsearch
        #
        def results
          @results ||= Results.new(klass, response)
        end

        # Return the collection of records from the database
        #
        def records
          @records ||= Records.new(klass, response, results)
        end

      end
    end
  end
end
