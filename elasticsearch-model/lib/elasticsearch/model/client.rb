# Licensed to Elasticsearch B.V. under one or more contributor
# license agreements. See the NOTICE file distributed with
# this work for additional information regarding copyright
# ownership. Elasticsearch B.V. licenses this file to you under
# the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#	http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

module Elasticsearch
  module Model

    # Contains an `Elasticsearch::Client` instance
    #
    module Client

      module ClassMethods

        # Get the client for a specific model class
        #
        # @example Get the client for `Article` and perform API request
        #
        #     Article.client.cluster.health
        #     # => { "cluster_name" => "elasticsearch" ... }
        #
        def client client=nil
          @client ||= Elasticsearch::Model.client
        end

        # Set the client for a specific model class
        #
        # @example Configure the client for the `Article` model
        #
        #     Article.client = Elasticsearch::Client.new host: 'http://api.server:8080'
        #     Article.search ...
        #
        def client=(client)
          @client = client
        end
      end

      module InstanceMethods

        # Get or set the client for a specific model instance
        #
        # @example Get the client for a specific record and perform API request
        #
        #     @article = Article.first
        #     @article.client.info
        #     # => { "name" => "Node-1", ... }
        #
        def client
          @client ||= self.class.client
        end

        # Set the client for a specific model instance
        #
        # @example Set the client for a specific record
        #
        #     @article = Article.first
        #     @article.client = Elasticsearch::Client.new host: 'http://api.server:8080'
        #
        def client=(client)
          @client = client
        end
      end

    end
  end
end
