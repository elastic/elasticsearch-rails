module Elasticsearch
  module Model
    module Support

      # Lightweight wrapper around "forwardable.rb" interface,
      # to allow easy delegation implementation changes in the future.
      #
      # Cf. https://github.com/mongoid/origin/blob/master/lib/origin/forwardable.rb
      #
      module Forwardable
        def self.extended(base)
          base.__send__ :extend, ::Forwardable
        end

        # Forwards specific method(s) to the provided receiver
        #
        # @example Forward the `each` method to `results` object
        #
        #   MyClass.forward(:results, :each)
        #
        # @param [ Symbol ] receiver        The name of the receiver method
        # @param [ Symbol, Array ] methods  The forwarded methods
        #
        # @api private
        #
        def forward(receiver, *methods)
          methods = Array(methods).flatten

          def_delegators receiver, *methods

        end; module_function :forward
      end
    end
  end
end
