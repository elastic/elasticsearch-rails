module Elasticsearch
  module Persistence

    module Client
      def client client=nil
        @client ||= Elasticsearch::Persistence.client
      end

      def client=(client)
        @client = client
      end
    end

  end
end
