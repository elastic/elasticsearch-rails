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
      # Common funtionality for classes in the {Elasticsearch::Model::Response} module
      #
      module Base
        attr_reader :klass, :response, :raw_response

        # @param klass    [Class] The name of the model class
        # @param response [Hash]  The full response returned from Elasticsearch client
        # @param options  [Hash]  Optional parameters
        #
        def initialize(klass, response, options={})
          @klass     = klass
          @raw_response = response
          @response = response
        end

        # @abstract Implement this method in specific class
        #
        def results
          raise NotImplemented, "Implement this method in #{klass}"
        end

        # @abstract Implement this method in specific class
        #
        def records
          raise NotImplemented, "Implement this method in #{klass}"
        end

        # Returns the total number of hits
        #
        def total
          if response.response['hits']['total'].respond_to?(:keys)
            response.response['hits']['total']['value']
          else
            response.response['hits']['total']
          end
        end

        # Returns the max_score
        #
        def max_score
          response.response['hits']['max_score']
        end
      end
    end
  end
end
