module Elasticsearch
  module Model

    # This module provides a proxy interfacing between the including class and
    # Elasticsearch::Model, preventing polluting the including class namespace.
    #
    # The only "gateway" between the model and Elasticsearch::Model is the
    # `__elasticsearch__` class and instance method.
    #
    # The including class must be compatible with
    # [ActiveModel](https://github.com/rails/rails/tree/master/activemodel).
    #
    # @example Include the {Elasticsearch::Model} module into an `Article` model
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
    #     article.respond_to? :as_indexed_json
    #     # => false
    #
    #     article.__elasticsearch__.respond_to?(:as_indexed_json)
    #     # => true
    #
    module Proxy

      # Define the `__elasticsearch__` class and instance methods
      # in including class.
      #
      def self.included(base)
        base.class_eval do
          # {ClassMethodsProxy} instance, accessed as `MyModel.__elasticsearch__`
          #
          def self.__elasticsearch__ &block
            @__elasticsearch__ ||= ClassMethodsProxy.new(self)
            @__elasticsearch__.instance_eval(&block) if block_given?
            @__elasticsearch__
          end

          # {InstanceMethodsProxy}, accessed as `@mymodel.__elasticsearch__`
          #
          def __elasticsearch__ &block
            @__elasticsearch__ ||= InstanceMethodsProxy.new(self)
            @__elasticsearch__.instance_eval(&block) if block_given?
            @__elasticsearch__
          end
        end
      end

      # A proxy interfacing between Elasticsearch::Model class methods and model class methods
      #
      # TODO: Inherit from BasicObject and make Pry's `ls` command behave
      #
      class ClassMethodsProxy
        attr_reader :klass

        def initialize(klass)
          @klass = klass
        end

        # Delegate methods to `@klass`
        #
        def method_missing(method_name, *arguments, &block)
          klass.respond_to?(method_name) ? klass.__send__(method_name, *arguments, &block) : super
        end

        # Respond to methods from `@klass`
        #
        def respond_to?(method_name, include_private = false)
          klass.respond_to?(method_name) || super
        end

        def inspect
          "[PROXY] #{klass.inspect}"
        end
      end

      # A proxy interfacing between Elasticsearch::Model instance methods and model instance methods
      #
      # TODO: Inherit from BasicObject and make Pry's `ls` command behave
      #
      class InstanceMethodsProxy
        attr_reader :instance

        def initialize(instance)
          @instance = instance
        end

        # Return the class of the target (instance class object)
        #
        def klass
          instance.class
        end

        # Return the `ClassMethodsProxy` instance (instance class' `__elasticsearch__` object)
        #
        def class
          klass.__elasticsearch__
        end

        def inspect
          "[PROXY] #{instance.inspect}"
        end

        def as_json(options={})
          instance.as_json(options)
        end

        # Delegate methods to `@instance`
        #
        def method_missing(method_name, *arguments, &block)
          instance.respond_to?(method_name) ? instance.__send__(method_name, *arguments, &block) : super
        end

        # Respond to methods from `@instance`
        #
        def respond_to?(method_name, include_private = false)
          instance.respond_to?(method_name) || super
        end
      end

    end
  end
end
