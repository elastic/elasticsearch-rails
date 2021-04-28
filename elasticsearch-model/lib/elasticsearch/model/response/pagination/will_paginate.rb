# Licensed to Elasticsearch B.V. under one or more contributor
# license agreements. See the NOTICE file distributed with
# this work for additional information regarding copyright
# ownership. Elasticsearch B.V. licenses this file to you under
# the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
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

      # Pagination for search results/records
      #
      module Pagination


        # Allow models to be paginated with the "will_paginate" gem [https://github.com/mislav/will_paginate]
        #
        module WillPaginate
          def self.included(base)
            base.__send__ :include, ::WillPaginate::CollectionMethods

            # Include the paging methods in results and records
            #
            methods = [:current_page, :offset, :length, :per_page, :total_entries, :total_pages, :previous_page, :next_page, :out_of_bounds?]
            Elasticsearch::Model::Response::Results.__send__ :delegate, *methods, to: :response
            Elasticsearch::Model::Response::Records.__send__ :delegate, *methods, to: :response
          end

          def offset
            (current_page - 1) * per_page
          end

          def length
            search.definition[:size]
          end

          # Main pagination method
          #
          # @example
          #
          #     Article.search('foo').paginate(page: 1, per_page: 30)
          #
          def paginate(options)
            param_name = options[:param_name] || :page
            page       = [options[param_name].to_i, 1].max
            per_page   = (options[:per_page] || __default_per_page).to_i

            search.definition.update size: per_page,
                                     from: (page - 1) * per_page
            self
          end

          # Return the current page
          #
          def current_page
            search.definition[:from] / per_page + 1 if search.definition[:from] && per_page
          end

          # Pagination method
          #
          # @example
          #
          #     Article.search('foo').page(2)
          #
          def page(num)
            paginate(page: num, per_page: per_page) # shorthand
          end

          # Return or set the "size" value
          #
          # @example
          #
          #     Article.search('foo').per_page(15).page(2)
          #
          def per_page(num = nil)
            if num.nil?
              search.definition[:size]
            else
              paginate(page: current_page, per_page: num) # shorthand
            end
          end

          # Returns the total number of results
          #
          def total_entries
            results.total
          end

          # Returns the models's `per_page` value or the default
          #
          # @api private
          #
          def __default_per_page
            klass.respond_to?(:per_page) && klass.per_page || ::WillPaginate.per_page
          end
        end
      end

    end
  end
end
