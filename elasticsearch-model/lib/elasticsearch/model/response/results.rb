module Elasticsearch
  module Model
    module Response
      class Results
        include Base

        attr_reader :klass, :results

        include Enumerable

        extend  Forwardable
        def_delegators :results, :each, :empty?, :size, :slice, :[], :to_a, :to_ary

        def initialize(klass, response)
          super
          @results   = response['hits']['hits'].map { |hit| Result.new(hit) }
        end

      end
    end
  end
end
