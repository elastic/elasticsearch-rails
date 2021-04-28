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

    # Contains an adapter which provides OxM-specific implementations for common behaviour:
    #
    # * {Adapter::Adapter#records_mixin   Fetching records from the database}
    # * {Adapter::Adapter#callbacks_mixin Model callbacks for automatic index updates}
    # * {Adapter::Adapter#importing_mixin Efficient bulk loading from the database}
    #
    # @see Elasticsearch::Model::Adapter::Default
    # @see Elasticsearch::Model::Adapter::ActiveRecord
    # @see Elasticsearch::Model::Adapter::Mongoid
    #
    module Adapter

      # Returns an adapter based on the Ruby class passed
      #
      # @example Create an adapter for an ActiveRecord-based model
      #
      #     class Article < ActiveRecord::Base; end
      #
      #     myadapter = Elasticsearch::Model::Adapter.from_class(Article)
      #     myadapter.adapter
      #     # => Elasticsearch::Model::Adapter::ActiveRecord
      #
      # @see Adapter.adapters The list of included adapters
      # @see Adapter.register Register a custom adapter
      #
      def from_class(klass)
        Adapter.new(klass)
      end; module_function :from_class

      # Returns registered adapters
      #
      # @see ::Elasticsearch::Model::Adapter::Adapter.adapters
      #
      def adapters
        Adapter.adapters
      end; module_function :adapters

      # Registers an adapter
      #
      # @see ::Elasticsearch::Model::Adapter::Adapter.register
      #
      def register(name, condition)
        Adapter.register(name, condition)
      end; module_function :register

      # Contains an adapter for specific OxM or architecture.
      #
      class Adapter
        attr_reader :klass

        def initialize(klass)
          @klass = klass
        end

        # Registers an adapter for specific condition
        #
        # @param name      [Module] The module containing the implemented interface
        # @param condition [Proc]   An object with a `call` method which is evaluated in {.adapter}
        #
        # @example Register an adapter for DataMapper
        #
        #     module DataMapperAdapter
        #
        #       # Implement the interface for fetching records
        #       #
        #       module Records
        #         def records
        #           klass.all(id: @ids)
        #         end
        #
        #         # ...
        #       end
        #     end
        #
        #     # Register the adapter
        #     #
        #     Elasticsearch::Model::Adapter.register(
        #       DataMapperAdapter,
        #       lambda { |klass|
        #         defined?(::DataMapper::Resource) and klass.ancestors.include?(::DataMapper::Resource)
        #       }
        #     )
        #
        def self.register(name, condition)
          self.adapters[name] = condition
        end

        # Return the collection of registered adapters
        #
        # @example Return the currently registered adapters
        #
        #     Elasticsearch::Model::Adapter.adapters
        #     # => {
        #     #  Elasticsearch::Model::Adapter::ActiveRecord => #<Proc:0x007...(lambda)>,
        #     #  Elasticsearch::Model::Adapter::Mongoid => #<Proc:0x007... (lambda)>,
        #     # }
        #
        # @return [Hash] The collection of adapters
        #
        def self.adapters
          @adapters ||= {}
        end

        # Return the module with {Default::Records} interface implementation
        #
        # @api private
        #
        def records_mixin
          adapter.const_get(:Records)
        end

        # Return the module with {Default::Callbacks} interface implementation
        #
        # @api private
        #
        def callbacks_mixin
          adapter.const_get(:Callbacks)
        end

        # Return the module with {Default::Importing} interface implementation
        #
        # @api private
        #
        def importing_mixin
          adapter.const_get(:Importing)
        end

        # Returns the adapter module
        #
        # @api private
        #
        def adapter
          @adapter ||= begin
            self.class.adapters.find( lambda {[]} ) { |name, condition| condition.call(klass) }.first \
            || Elasticsearch::Model::Adapter::Default
          end
        end

      end
    end
  end
end
