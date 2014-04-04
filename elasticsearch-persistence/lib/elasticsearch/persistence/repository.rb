module Elasticsearch
  module Persistence
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

    module Repository
      def self.included(base)
        gateway = Elasticsearch::Persistence::Repository::Class.new host: base

        base.class_eval do
          define_method :gateway do
            @gateway ||= gateway
          end

          include GatewayDelegation
        end

        (class << base; self; end).class_eval do
          define_method :gateway do |&block|
            @gateway ||= gateway
            @gateway.instance_eval(&block) if block
            @gateway
          end

          include GatewayDelegation
        end

        def base.method_added(name)
          if :gateway != name && respond_to?(:gateway) && (gateway.public_methods - Object.public_methods).include?(name)
            gateway.define_singleton_method(name, self.new.method(name).to_proc)
          end
        end
      end

      def new(options={}, &block)
        Elasticsearch::Persistence::Repository::Class.new( {index: 'repository'}.merge(options), &block )
      end; module_function :new
    end
  end
end
