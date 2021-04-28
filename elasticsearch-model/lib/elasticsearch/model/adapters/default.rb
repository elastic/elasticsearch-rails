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
    module Adapter

      # The default adapter for models which haven't one registered
      #
      module Default

        # Module for implementing methods and logic related to fetching records from the database
        #
        module Records

          # Return the collection of records fetched from the database
          #
          # By default uses `MyModel#find[1, 2, 3]`
          #
          def records
            klass.find(@ids)
          end
        end

        # Module for implementing methods and logic related to hooking into model lifecycle
        # (e.g. to perform automatic index updates)
        #
        # @see http://api.rubyonrails.org/classes/ActiveModel/Callbacks.html
        module Callbacks
          # noop
        end

        # Module for efficiently fetching records from the database to import them into the index
        #
        module Importing

          # @abstract Implement this method in your adapter
          #
          def __find_in_batches(options={}, &block)
            raise NotImplemented, "Method not implemented for default adapter"
          end

          # @abstract Implement this method in your adapter
          #
          def __transform
            raise NotImplemented, "Method not implemented for default adapter"
          end
        end

      end
    end
  end
end
