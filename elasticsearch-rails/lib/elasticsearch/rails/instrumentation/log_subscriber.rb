module Elasticsearch
  module Rails
    module Instrumentation

      # A log subscriber to attach to Elasticsearch related events
      #
      # @see https://github.com/rails/rails/blob/master/activerecord/lib/active_record/log_subscriber.rb
      #
      class LogSubscriber < ActiveSupport::LogSubscriber
        def self.runtime=(value)
          Thread.current["elasticsearch_runtime"] = value
        end

        def self.runtime
          Thread.current["elasticsearch_runtime"] ||= 0
        end

        def self.reset_runtime
          rt, self.runtime = runtime, 0
          rt
        end

        # Intercept `search.elasticsearch` events, and display them in the Rails log
        #
        def search(event)
          self.class.runtime += event.duration
          return unless logger.debug?

          payload = event.payload
          name    = "#{payload[:klass]} #{payload[:name]} (#{event.duration.round(1)}ms)"
          search  = payload[:search].inspect.gsub(/:(\w+)=>/, '\1: ')

          debug %Q|  #{color(name, GREEN, true)} #{colorize_logging ? "\e[2m#{search}\e[0m" : search}|
        end
      end

    end
  end
end

Elasticsearch::Rails::Instrumentation::LogSubscriber.attach_to :elasticsearch
