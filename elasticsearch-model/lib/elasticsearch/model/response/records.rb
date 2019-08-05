# Licensed to Elasticsearch B.V. under one or more contributor
# license agreements. See the NOTICE file distributed with
# this work for additional information regarding copyright
# ownership. Elasticsearch B.V. licenses this file to you under
# the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#	http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

module Elasticsearch
  module Model
    module Response

      # Encapsulates the collection of records returned from the database
      #
      # Implements Enumerable and forwards its methods to the {#records} object,
      # which is provided by an {Elasticsearch::Model::Adapter::Adapter} implementation.
      #
      class Records
        include Enumerable

        delegate :each, :empty?, :size, :slice, :[], :to_a, :to_ary, to: :records

        attr_accessor :options

        include Base

        # @see Base#initialize
        #
        def initialize(klass, response, options={})
          super

          # Include module provided by the adapter in the singleton class ("metaclass")
          #
          adapter = Adapter.from_class(klass)
          metaclass = class << self; self; end
          metaclass.__send__ :include, adapter.records_mixin

          self.options = options
        end

        # Returns the hit IDs
        #
        def ids
          response.response['hits']['hits'].map { |hit| hit['_id'] }
        end

        # Returns the {Results} collection
        #
        def results
          response.results
        end

        # Yields [record, hit] pairs to the block
        #
        def each_with_hit(&block)
          records.to_a.zip(results).each(&block)
        end

        # Yields [record, hit] pairs and returns the result
        #
        def map_with_hit(&block)
          records.to_a.zip(results).map(&block)
        end

        # Delegate methods to `@records`
        #
        def method_missing(method_name, *arguments)
          records.respond_to?(method_name) ? records.__send__(method_name, *arguments) : super
        end

        # Respond to methods from `@records`
        #
        def respond_to?(method_name, include_private = false)
          records.respond_to?(method_name) || super
        end

      end
    end
  end
end
