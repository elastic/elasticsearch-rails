module Elasticsearch
  module Model
    module Response
      class Response
        attr_reader :klass, :response

        include Enumerable
        extend  Support::Forwardable

        forward :results, :each, :empty?, :size, :slice, :[], :to_ary

        def initialize(klass, response)
          @klass    = klass
          @response = response
        end

        def results
          @results ||= Results.new(klass, response)
        end

        def records
          @records ||= Records.new(klass, response)
        end

      end
    end
  end
end
