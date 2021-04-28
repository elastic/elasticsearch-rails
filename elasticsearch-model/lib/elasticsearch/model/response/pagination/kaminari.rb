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
        # Allow models to be paginated with the "kaminari" gem [https://github.com/amatsuda/kaminari]
        #
        module Kaminari
          def self.included(base)
            # Include the Kaminari configuration and paging method in response
            #
            base.__send__ :include, ::Kaminari::ConfigurationMethods::ClassMethods
            base.__send__ :include, ::Kaminari::PageScopeMethods

            # Include the Kaminari paging methods in results and records
            #
            Elasticsearch::Model::Response::Results.__send__ :include, ::Kaminari::ConfigurationMethods::ClassMethods
            Elasticsearch::Model::Response::Results.__send__ :include, ::Kaminari::PageScopeMethods
            Elasticsearch::Model::Response::Records.__send__ :include, ::Kaminari::PageScopeMethods

            Elasticsearch::Model::Response::Results.__send__ :delegate, :limit_value, :offset_value, :total_count, :max_pages, to: :response
            Elasticsearch::Model::Response::Records.__send__ :delegate, :limit_value, :offset_value, :total_count, :max_pages, to: :response

            base.class_eval <<-RUBY, __FILE__, __LINE__ + 1
              # Define the `page` Kaminari method
              #
              def #{::Kaminari.config.page_method_name}(num=nil)
                @results  = nil
                @records  = nil
                @response = nil
                @page     = [num.to_i, 1].max
                @per_page ||= __default_per_page

                self.search.definition.update size: @per_page,
                                              from: @per_page * (@page - 1)

                self
              end
            RUBY
          end

          # Returns the current "limit" (`size`) value
          #
          def limit_value
            case
            when search.definition[:size]
              search.definition[:size]
            else
              __default_per_page
            end
          end

          # Returns the current "offset" (`from`) value
          #
          def offset_value
            case
            when search.definition[:from]
              search.definition[:from]
            else
              0
            end
          end

          # Set the "limit" (`size`) value
          #
          def limit(value)
            return self if value.to_i <= 0
            @results  = nil
            @records  = nil
            @response = nil
            @per_page = value.to_i

            search.definition.update :size => @per_page
            search.definition.update :from => @per_page * (@page - 1) if @page
            self
          end

          # Set the "offset" (`from`) value
          #
          def offset(value)
            return self if value.to_i < 0
            @results  = nil
            @records  = nil
            @response = nil
            @page     = nil
            search.definition.update :from => value.to_i
            self
          end

          # Returns the total number of results
          #
          def total_count
            results.total
          end

          # Returns the models's `per_page` value or the default
          #
          # @api private
          #
          def __default_per_page
            klass.respond_to?(:default_per_page) && klass.default_per_page || ::Kaminari.config.default_per_page
          end
        end
      end
    end
  end
end
