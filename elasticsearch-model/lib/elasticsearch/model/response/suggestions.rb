module Elasticsearch
  module Model
    module Response

      class Suggestions < Hashie::Mash
        def terms
          self.to_a.map { |k,v| v.first['options'] }.flatten.map {|v| v['text']}.uniq
        end
      end

    end
  end
end
