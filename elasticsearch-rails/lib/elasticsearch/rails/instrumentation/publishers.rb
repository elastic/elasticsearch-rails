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
  module Rails
    module Instrumentation
      module Publishers

        # Wraps the `SearchRequest` methods to perform the instrumentation
        #
        # @see SearchRequest#execute_with_instrumentation!
        # @see http://api.rubyonrails.org/classes/ActiveSupport/Notifications.html
        #
        module SearchRequest

          def self.included(base)
            base.class_eval do
              unless method_defined?(:execute_without_instrumentation!)
                alias_method :execute_without_instrumentation!, :execute!
                alias_method :execute!, :execute_with_instrumentation!
              end
            end
          end

          # Wrap `Search#execute!` and perform instrumentation
          #
          def execute_with_instrumentation!
            ActiveSupport::Notifications.instrument "search.elasticsearch",
              name:   'Search',
              klass:  (self.klass.is_a?(Elasticsearch::Model::Proxy::ClassMethodsProxy) ? self.klass.target.to_s : self.klass.to_s),
              search: self.definition do
              execute_without_instrumentation!
            end
          end
        end
      end
    end
  end
end
