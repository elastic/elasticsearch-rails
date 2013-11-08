module Elasticsearch
  module Model
    module Client

      module ClassMethods

        # Get or set the client for a specific model
        #
        def client client=nil
          @client = client || @client || Elasticsearch::Model.client
        end
      end

    end
  end
end
