require 'elasticsearch'

require 'elasticsearch/persistence/version'

require 'elasticsearch/persistence/client'
require 'elasticsearch/persistence/repository'

require 'elasticsearch/persistence/repository/class'

module Elasticsearch
  module Persistence

    # :nodoc:
    module ClassMethods
      def client
        @client ||= Elasticsearch::Client.new
      end

      def client=(client)
        @client = client
      end
    end

    extend ClassMethods
  end
end
