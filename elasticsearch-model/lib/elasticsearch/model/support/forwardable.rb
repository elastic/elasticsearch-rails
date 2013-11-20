module Elasticsearch
  module Model
    module Support

      # Lightweight wrapper around "forwardable.rb" interface,
      # to allow easy implementation changes in the future.
      #
      # Cf. https://github.com/mongoid/origin/blob/master/lib/origin/forwardable.rb
      #
      module Forwardable
        def self.extended(base)
          base.__send__ :extend, ::Forwardable
          base.__send__ :extend, ::SingleForwardable
        end

        # Forwards specific method(s) to the provided receiver
        #
        # @example Forward the `each` method to `results` object
        #
        #   MyClass.forward(:results, :each)
        #
        # @example Forward the `include?` method to `ancestors` class method
        #
        #   MyClass.forward(:'self.ancestors', :include?)
        #
        # @param [ Symbol ] receiver        The name of the receiver method
        # @param [ Symbol, Array ] methods  The forwarded methods
        #
        # @api private
        #
        def forward(receiver, *methods)
          methods = Array(methods).flatten
          target  = self.__send__ :eval, receiver.to_s rescue nil

          if target
            single_delegate   methods => receiver
          else
            instance_delegate methods => receiver
          end
        end; module_function :forward
      end
    end
  end
end
