module Elasticsearch
  module Model
    module Callbacks

      def self.included(base)
        adapter = Adapter.from_class(base)
        base.__send__ :include, adapter.callbacks_mixin
      end

    end
  end
end
