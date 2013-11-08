module Elasticsearch
  module Model
    module Client

      module ClassMethods

        # Get or set the client
        #
        def client client=nil
          @client = client || @client || Elasticsearch::Client.new
        end
      end

    end
  end
end
