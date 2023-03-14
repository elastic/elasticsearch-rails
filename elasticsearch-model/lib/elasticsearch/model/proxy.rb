module Elasticsearch
  module Model

    # This module provides a proxy interfacing between the including class and
    # {Elasticsearch::Model}, preventing the pollution of the including class namespace.
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

          # Register a callback for storing changed attributes for models which implement
          # `before_save` method and return changed attributes (ie. when `Elasticsearch::Model` is included)
          #
          # @see http://api.rubyonrails.org/classes/ActiveModel/Dirty.html
          #
          before_save do |i|
            if i.class.instance_methods.include?(:changes_to_save) # Rails 5.1
              a = i.__elasticsearch__.instance_variable_get(:@__changed_model_attributes) || {}
              i.__elasticsearch__.instance_variable_set(:@__changed_model_attributes,
                                                        a.merge(Hash[ i.changes_to_save.map { |key, value| [key, value.last] } ]))
            elsif i.class.instance_methods.include?(:changes)
              a = i.__elasticsearch__.instance_variable_get(:@__changed_model_attributes) || {}
              i.__elasticsearch__.instance_variable_set(:@__changed_model_attributes,
                                                        a.merge(Hash[ i.changes.map { |key, value| [key, value.last] } ]))
            end
          end if respond_to?(:before_save)
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

        def ruby2_keywords(*) # :nodoc:
        end if RUBY_VERSION < "2.7"

        # Delegate methods to `@target`. As per [the Ruby 3.0 explanation for keyword arguments](https://www.ruby-lang.org/en/news/2019/12/12/separation-of-positional-and-keyword-arguments-in-ruby-3-0/), the only way to work on Ruby <2.7, and 2.7, and 3.0+ is to use `ruby2_keywords`.
        #
        ruby2_keywords def method_missing(method_name, *arguments, &block)
          target.respond_to?(method_name) ? target.__send__(method_name, *arguments, &block) : super
        end

        # Respond to methods from `@target`
        #
        def respond_to_missing?(method_name, include_private = false)
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
      end

      # A proxy interfacing between Elasticsearch::Model instance methods and model instance methods
      #
      # TODO: Inherit from BasicObject and make Pry's `ls` command behave?
      #
      class InstanceMethodsProxy
        include Base

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
      end

    end
  end
end
