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

module Elasticsearch
  module Rails
    module Instrumentation

      # Hooks into ActionController to display Elasticsearch runtime
      #
      # @see https://github.com/rails/rails/blob/master/activerecord/lib/active_record/railties/controller_runtime.rb
      #
      module ControllerRuntime
        extend ActiveSupport::Concern

        protected

        attr_internal :elasticsearch_runtime

        def cleanup_view_runtime
          elasticsearch_rt_before_render = Elasticsearch::Rails::Instrumentation::LogSubscriber.reset_runtime
          runtime = super
          elasticsearch_rt_after_render = Elasticsearch::Rails::Instrumentation::LogSubscriber.reset_runtime
          self.elasticsearch_runtime = elasticsearch_rt_before_render + elasticsearch_rt_after_render
          runtime - elasticsearch_rt_after_render
        end

        def append_info_to_payload(payload)
          super
          payload[:elasticsearch_runtime] = (elasticsearch_runtime || 0) + Elasticsearch::Rails::Instrumentation::LogSubscriber.reset_runtime
        end

        module ClassMethods
          def log_process_action(payload)
            messages, elasticsearch_runtime = super, payload[:elasticsearch_runtime]
            messages << ("Elasticsearch: %.1fms" % elasticsearch_runtime.to_f) if elasticsearch_runtime
            messages
          end
        end
      end
    end
  end
end
