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

    # Contains modules and classes for wrapping the response from Elasticsearch
    #
    module Response

      # Encapsulate the response returned from the Elasticsearch client
      #
      # Implements Enumerable and forwards its methods to the {#results} object.
      #
      class Response
        attr_reader :klass, :search

        include Enumerable

        delegate :each, :empty?, :size, :slice, :[], :to_ary, to: :results

        def initialize(klass, search, options={})
          @klass     = klass
          @search    = search
        end

        # Returns the Elasticsearch response
        #
        # @return [Hash]
        #
        def response
          @response ||= HashWrapper.new(search.execute!)
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
        def records(options = {})
          @records ||= Records.new(klass, self, options)
        end

        # Returns the "took" time
        #
        def took
          raw_response['took']
        end

        # Returns whether the response timed out
        #
        def timed_out
          raw_response['timed_out']
        end

        # Returns the statistics on shards
        #
        def shards
          @shards ||= response['_shards']
        end

        # Returns a Hashie::Mash of the aggregations
        #
        def aggregations
          @aggregations ||= Aggregations.new(raw_response['aggregations'])
        end

        # Returns a Hashie::Mash of the suggestions
        #
        def suggestions
          @suggestions ||= Suggestions.new(raw_response['suggest'])
        end

        def raw_response
          @raw_response ||= @response ? @response.to_hash : search.execute!
        end
      end
    end
  end
end
