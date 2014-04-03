module Elasticsearch
  module Persistence
    module Repository

      module Client
        def client client=nil
          @client = client || @client || Elasticsearch::Persistence.client
        end

        def client=(client)
          @client = client
          @client
        end
      end

    end
  end
end
