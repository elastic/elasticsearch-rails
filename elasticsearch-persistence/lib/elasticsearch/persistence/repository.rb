module Elasticsearch
  module Persistence

    # Delegate methods to the repository (acting as a gateway)
    #
    module GatewayDelegation
      def method_missing(method_name, *arguments, &block)
        gateway.respond_to?(method_name) ? gateway.__send__(method_name, *arguments, &block) : super
      end

      def respond_to?(method_name, include_private=false)
        gateway.respond_to?(method_name) || super
      end

      def respond_to_missing?(method_name, *)
        gateway.respond_to?(method_name) || super
      end
    end

    # When included, creates an instance of the {Repository::Class} class as a "gateway"
    #
    # @example Include the repository in a custom class
    #
    #     class MyRepository
    #       include Elasticsearch::Persistence::Repository
    #     end
    #
    module Repository
      def self.included(base)
        gateway = Elasticsearch::Persistence::Repository::Class.new host: base

        # Define the instance level gateway
        #
        base.class_eval do
          define_method :gateway do
            @gateway ||= gateway
          end

          include GatewayDelegation
        end

        # Define the class level gateway
        #
        (class << base; self; end).class_eval do
          define_method :gateway do |&block|
            @gateway ||= gateway
            @gateway.instance_eval(&block) if block
            @gateway
          end

          include GatewayDelegation
        end

        # Catch repository methods (such as `serialize` and others) defined in the receiving class,
        # and overload the default definition in the gateway
        #
        def base.method_added(name)
          if :gateway != name && respond_to?(:gateway) && (gateway.public_methods - Object.public_methods).include?(name)
            gateway.define_singleton_method(name, self.new.method(name).to_proc)
          end
        end
      end

      # Shortcut method to allow concise repository initialization
      #
      # @example Create a new default repository
      #
      #     repository = Elasticsearch::Persistence::Repository.new
      #
      def new(options={}, &block)
        Elasticsearch::Persistence::Repository::Class.new( {index: 'repository'}.merge(options), &block )
      end; module_function :new
    end
  end
end
