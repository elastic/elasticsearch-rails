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

    # This module provides a proxy interfacing between the including class and
    # `Elasticsearch::Model`, preventing the pollution of the including class namespace.
    #
    # The only "gateway" between the model and Elasticsearch::Model is the
    # `#__elasticsearch__` class and instance method.
    #
    # The including class must be compatible with
    # [ActiveModel](https://github.com/rails/rails/tree/master/activemodel).
    #
    # @example Include the `Elasticsearch::Model` module into an `Article` model
    #
    #     class Article < ActiveRecord::Base
    #       include Elasticsearch::Model
    #     end
    #
    #     Article.__elasticsearch__.respond_to?(:search)
    #     # => true
    #
    #     article = Article.first
    #
    #     article.respond_to? :index_document
    #     # => false
    #
    #     article.__elasticsearch__.respond_to?(:index_document)
    #     # => true
    #
    module Proxy

      # Define the `__elasticsearch__` class and instance methods in the including class
      # and register a callback for intercepting changes in the model.
      #
      # @note The callback is triggered only when `Elasticsearch::Model` is included in the
      #       module and the functionality is accessible via the proxy.
      #
      def self.included(base)

        base.class_eval do

          # `ClassMethodsProxy` instance, accessed as `MyModel.__elasticsearch__`
          def self.__elasticsearch__ &block
            @__elasticsearch__ ||= ClassMethodsProxy.new(self)
            @__elasticsearch__.instance_eval(&block) if block_given?
            @__elasticsearch__
          end

          # Mix the importing module into the `ClassMethodsProxy`
          self.__elasticsearch__.class_eval do
            include Adapter.from_class(base).importing_mixin
          end

          # Register a callback for storing changed attributes for models which implement
          # `before_save` method and return changed attributes (ie. when `Elasticsearch::Model` is included)
          #
          # @see http://api.rubyonrails.org/classes/ActiveModel/Dirty.html
          #
          before_save do |obj|
            if obj.respond_to?(:changes_to_save) # Rails 5.1
              changes_to_save = obj.changes_to_save
            elsif obj.respond_to?(:changes)
              changes_to_save = obj.changes
            end

            if changes_to_save
              attrs = obj.__elasticsearch__.instance_variable_get(:@__changed_model_attributes) || {}
              latest_changes = changes_to_save.inject({}) { |latest_changes, (k,v)| latest_changes.merge!(k => v.last) }
              obj.__elasticsearch__.instance_variable_set(:@__changed_model_attributes, attrs.merge(latest_changes))
            end
          end if respond_to?(:before_save)
        end

        # {InstanceMethodsProxy}, accessed as `@mymodel.__elasticsearch__`
        #
        def __elasticsearch__ &block
          @__elasticsearch__ ||= InstanceMethodsProxy.new(self)
          @__elasticsearch__.instance_eval(&block) if block_given?
          @__elasticsearch__
        end
      end

      # @overload dup
      #
      # Returns a copy of this object. Resets the __elasticsearch__ proxy so
      # the duplicate will build its own proxy.
      def initialize_dup(_)
        @__elasticsearch__ = nil
        super
      end

      # Common module for the proxy classes
      #
      module Base
        attr_reader :target

        def initialize(target)
          @target = target
        end

        # Delegate methods to `@target`
        #
        def method_missing(method_name, *arguments, &block)
          target.respond_to?(method_name) ? target.__send__(method_name, *arguments, &block) : super
        end

        # Respond to methods from `@target`
        #
        def respond_to?(method_name, include_private = false)
          target.respond_to?(method_name) || super
        end

        def inspect
          "[PROXY] #{target.inspect}"
        end
      end

      # A proxy interfacing between Elasticsearch::Model class methods and model class methods
      #
      # TODO: Inherit from BasicObject and make Pry's `ls` command behave?
      #
      class ClassMethodsProxy
        include Base
        include Elasticsearch::Model::Client::ClassMethods
        include Elasticsearch::Model::Naming::ClassMethods
        include Elasticsearch::Model::Indexing::ClassMethods
        include Elasticsearch::Model::Searching::ClassMethods
        include Elasticsearch::Model::Importing::ClassMethods
      end

      # A proxy interfacing between Elasticsearch::Model instance methods and model instance methods
      #
      # TODO: Inherit from BasicObject and make Pry's `ls` command behave?
      #
      class InstanceMethodsProxy
        include Base
        include Elasticsearch::Model::Client::InstanceMethods
        include Elasticsearch::Model::Naming::InstanceMethods
        include Elasticsearch::Model::Indexing::InstanceMethods
        include Elasticsearch::Model::Serializing::InstanceMethods

        def klass
          target.class
        end

        def class
          klass.__elasticsearch__
        end

        # Need to redefine `as_json` because we're not inheriting from `BasicObject`;
        # see TODO note above.
        #
        def as_json(options={})
          target.as_json(options)
        end

        def as_indexed_json(options={})
          target.respond_to?(:as_indexed_json) ? target.__send__(:as_indexed_json, options) : super
        end
      end
    end
  end
end
