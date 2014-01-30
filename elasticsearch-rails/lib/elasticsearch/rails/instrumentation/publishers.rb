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
          extend ActiveSupport::Concern

          included do
            alias_method_chain :execute!, :instrumentation
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
