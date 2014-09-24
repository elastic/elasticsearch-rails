module Elasticsearch
  module Persistence
    module Model

      # Make the `Persistence::Model` models compatible with Ruby On Rails applications
      #
      module Rails
        def self.included(base)
          base.class_eval do

            def initialize(attributes={})
              super(__convert_rails_dates(attributes))
            end

            def update(attributes={}, options={})
              super(__convert_rails_dates(attributes))
            end
          end
        end

        # Decorates the passed in `attributes` so they extract the date & time values from Rails forms
        #
        # @example Correctly combine the date and time to a datetime string
        #
        #     params = { "published_on(1i)"=>"2014",
        #                      "published_on(2i)"=>"1",
        #                      "published_on(3i)"=>"1",
        #                      "published_on(4i)"=>"12",
        #                      "published_on(5i)"=>"00"
        #                     }
        #     MyRailsModel.new(params).published_on.iso8601
        #     # => "2014-01-01T12:00:00+00:00"
        #
        def __convert_rails_dates(attributes={})
          day = attributes.select { |p| p =~ /\([1-3]/ }.reduce({}) { |sum, item| (sum[item.first.gsub(/\(.+\)/, '')] ||= '' )<< item.last+'-'; sum  }
          time = attributes.select { |p| p =~ /\([4-6]/ }.reduce({}) { |sum, item| (sum[item.first.gsub(/\(.+\)/, '')] ||= '' )<< item.last+':'; sum  }
          unless day.empty?
            attributes.update day.reduce({}) { |sum, item| sum[item.first] = item.last; sum[item.first] += ' ' + time[item.first] unless time.empty?; sum }
          end

          return attributes
        end; module_function :__convert_rails_dates
      end

    end
  end
end
