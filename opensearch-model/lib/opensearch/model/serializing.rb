# Licensed to Elasticsearch B.V. under one or more contributor
# license agreements. See the NOTICE file distributed with
# this work for additional information regarding copyright
# ownership. Elasticsearch B.V. licenses this file to you under
# the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

module Elasticsearch
  module Model

    # Contains functionality for serializing model instances for the client
    #
    module Serializing

      module ClassMethods
      end

      module InstanceMethods

        # Serialize the record as a Hash, to be passed to the client.
        #
        # Re-define this method to customize the serialization.
        #
        # @return [Hash]
        #
        # @example Return the model instance as a Hash
        #
        #     Article.first.__elasticsearch__.as_indexed_json
        #     => {"title"=>"Foo"}
        #
        # @see Elasticsearch::Model::Indexing
        #
        def as_indexed_json(options={})
          # TODO: Play with the `MyModel.indexes` method -- reject non-mapped attributes, `:as` options, etc
          self.as_json(options.merge root: false)
        end

      end

    end
  end
end
