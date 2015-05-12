module Elasticsearch
  module Persistence
    module Model
      class TimeWithZoneTypecaster
        def initialize(precision = nil)
          @precision_override = precision
        end

        def call(value)
          result = nil
          if value.respond_to? :in_time_zone
            result = value.in_time_zone
          elsif value.respond_to? :to_s
            result = Time.zone.parse(value)
          end

          precision = nil
          if !@precision_override.nil?
            precision = @precision_override
          elsif !ActiveSupport::JSON::Encoding.use_standard_json_time_format
            precision = 0
          elsif Gem::Version.new(::Rails.version.to_s) < Gem::Version.new('4.0')
            precision = 0
          elsif Gem::Version.new(::Rails.version.to_s) >= Gem::Version.new('4.0') &&
            Gem::Version.new(::Rails.version.to_s) < Gem::Version.new('4.1')
            precision = 3
          else
            precision = ActiveSupport::JSON::Encoding.time_precision
          end

          result.change(usec: (result.usec / (10**(6-precision))))
        end
      end
    end
  end
end
