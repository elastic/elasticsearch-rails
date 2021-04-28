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
  module Persistence
    module Repository

      # Include this module to get class-level methods for repository configuration.
      #
      # @since 6.0.0
      module DSL

        def self.included(base)
          base.send(:extend, Elasticsearch::Model::Indexing::ClassMethods)
          base.send(:extend, ClassMethods)
        end

        # These methods are necessary to define at the class-level so that the methods available
        # via Elasticsearch::Model::Indexing::ClassMethods have the references they depend on.
        #
        # @since 6.0.0
        module ClassMethods

          # Get or set the class-level document type setting.
          #
          # @example
          #   MyRepository.document_type
          #
          # @return [ String, Symbol ] _type The repository's document type.
          #
          # @since 6.0.0
          def document_type(_type = nil)
            @document_type ||= _type
          end

          # Get or set the class-level index name setting.
          #
          # @example
          #   MyRepository.index_name
          #
          # @return [ String, Symbol ] _name The repository's index name.
          #
          # @since 6.0.0
          def index_name(_name = nil)
            @index_name ||= (_name || DEFAULT_INDEX_NAME)
          end

          # Get or set the class-level setting for the class used by the repository when deserializing.
          #
          # @example
          #   MyRepository.klass
          #
          # @return [ Class ] _class The repository's klass for deserializing.
          #
          # @since 6.0.0
          def klass(_class = nil)
            instance_variables.include?(:@klass) ? @klass : @klass = _class
          end

          # Get or set the class-level setting for the client used by the repository.
          #
          # @example
          #   MyRepository.client
          #
          # @return [ Class ] _client The repository's client.
          #
          # @since 6.0.0
          def client(_client = nil)
            @client ||= (_client || Elasticsearch::Client.new)
          end

          def create_index!(*args)
            __raise_not_implemented_error(__method__)
          end

          def delete_index!(*args)
            __raise_not_implemented_error(__method__)
          end

          def refresh_index!(*args)
            __raise_not_implemented_error(__method__)
          end

          def index_exists?(*args)
            __raise_not_implemented_error(__method__)
          end

          private

          def __raise_not_implemented_error(_method_)
            raise NotImplementedError, "The '#{_method_}' method is not implemented on the Repository class."
          end
        end
      end
    end
  end
end
