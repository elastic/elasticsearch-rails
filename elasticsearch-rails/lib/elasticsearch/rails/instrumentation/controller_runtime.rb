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
