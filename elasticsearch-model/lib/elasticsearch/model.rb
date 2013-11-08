require 'forwardable'

require 'elasticsearch'

require 'hashie'

require 'elasticsearch/model/support/forwardable'

require 'elasticsearch/model/client'

require 'elasticsearch/model/adapter'
require 'elasticsearch/model/adapters/default'
require 'elasticsearch/model/adapters/active_record'
require 'elasticsearch/model/adapters/mongoid'

require 'elasticsearch/model/response'
require 'elasticsearch/model/response/base'
require 'elasticsearch/model/response/result'
require 'elasticsearch/model/response/results'
require 'elasticsearch/model/response/records'
require 'elasticsearch/model/searching'

require 'elasticsearch/model/version'

module Elasticsearch
  module Model

    module ClassMethods

      # Get or set the client for all models
      #
      def client client=nil
        @client = client || @client || Elasticsearch::Client.new
      end

    end
    extend ClassMethods

  end
end
