require 'elasticsearch'
require 'elasticsearch/model/indexing'
require 'hashie'

require 'active_support/inflector'

require 'elasticsearch/persistence/version'

require 'elasticsearch/persistence/client'
require 'elasticsearch/persistence/repository/response/results'
require 'elasticsearch/persistence/repository/naming'
require 'elasticsearch/persistence/repository/serialize'
require 'elasticsearch/persistence/repository/store'
require 'elasticsearch/persistence/repository/find'
require 'elasticsearch/persistence/repository/search'
require 'elasticsearch/persistence/repository/class'
require 'elasticsearch/persistence/repository'

module Elasticsearch
  module Persistence

    # :nodoc:
    module ClassMethods
      def client client=nil
        @client = client || @client || Elasticsearch::Client.new
      end

      def client=(client)
        @client = client
      end
    end

    extend ClassMethods
  end
end
