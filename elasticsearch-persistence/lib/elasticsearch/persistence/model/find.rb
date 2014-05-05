module Elasticsearch
  module Persistence
    module Model

      module Find
        module ClassMethods

          # Return all documents (up to 10,000) for a model
          #
          # @example Retrieve all people
          #
          #     Person.all
          #     # => [#<Person:0x007ff1d8fb04b0 ... ]
          #
          # @example Retrieve all people matching a query
          #
          #     Person.all query: { match: { last_name: 'Smith'  } }
          #     # => [#<Person:0x007ff1d8fb04b0 ... ]
          #
          def all(options={})
            gateway.search( { query: { match_all: {} }, size: 10_000 }.merge(options) )
          end
        end
      end

    end
  end
end
