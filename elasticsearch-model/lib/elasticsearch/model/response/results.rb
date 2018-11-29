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

      # Encapsulates the collection of documents returned from Elasticsearch
      #
      # Implements Enumerable and forwards its methods to the {#results} object.
      #
      class Results
        include Base
        include Enumerable

        delegate :each, :empty?, :size, :slice, :[], :to_a, :to_ary, to: :results

        # @see Base#initialize
        #
        def initialize(klass, response, options={})
          super
        end

        # Returns the {Results} collection
        #
        def results
          # TODO: Configurable custom wrapper
          response.response['hits']['hits'].map { |hit| Result.new(hit) }
        end

      end
    end
  end
end
