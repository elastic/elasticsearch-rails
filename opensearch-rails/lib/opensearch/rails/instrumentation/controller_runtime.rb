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

require 'active_support/core_ext/module/attr_internal'

module OpenSearch
  module Rails
    module Instrumentation

      # Hooks into ActionController to display OpenSearch runtime
      #
      # @see https://github.com/rails/rails/blob/master/activerecord/lib/active_record/railties/controller_runtime.rb
      #
      module ControllerRuntime
        extend ActiveSupport::Concern

        protected

        attr_internal :opensearch_runtime

        def cleanup_view_runtime
          opensearch_rt_before_render = OpenSearch::Rails::Instrumentation::LogSubscriber.reset_runtime
          runtime = super
          opensearch_rt_after_render = OpenSearch::Rails::Instrumentation::LogSubscriber.reset_runtime
          self.opensearch_runtime = opensearch_rt_before_render + opensearch_rt_after_render
          runtime - opensearch_rt_after_render
        end

        def append_info_to_payload(payload)
          super
          payload[:opensearch_runtime] = (opensearch_runtime || 0) + OpenSearch::Rails::Instrumentation::LogSubscriber.reset_runtime
        end

        module ClassMethods
          def log_process_action(payload)
            messages, opensearch_runtime = super, payload[:opensearch_runtime]
            messages << ("OpenSearch: %.1fms" % opensearch_runtime.to_f) if opensearch_runtime
            messages
          end
        end
      end
    end
  end
end
