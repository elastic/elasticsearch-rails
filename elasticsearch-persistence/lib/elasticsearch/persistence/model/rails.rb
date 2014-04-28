module Elasticsearch
  module Persistence
    module Model

      module Rails
        def self.included(base)
          base.class_eval do
            def initialize(attributes={})
              day = attributes.select { |p| p =~ /\([1-3]/ }.reduce({}) { |sum, item| (sum[item.first.gsub(/\(.+\)/, '')] ||= '' )<< item.last+'-'; sum  }
              time = attributes.select { |p| p =~ /\([4-6]/ }.reduce({}) { |sum, item| (sum[item.first.gsub(/\(.+\)/, '')] ||= '' )<< item.last+':'; sum  }
              unless day.empty? && time.empty?
                attributes.update day.reduce({}) { |sum, item| sum[item.first] = item.last + ' ' + time[item.first]; sum }
              end
              super(attributes)
            end
          end
        end
      end

    end
  end
end
