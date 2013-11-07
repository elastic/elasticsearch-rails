module Elasticsearch
  module Model
    module Adapter
      module Mongoid

        Adapter.register self,
                         lambda { |klass| defined?(::Mongoid::Document) && klass.ancestors.include?(::Mongoid::Document) }

        module Records
          # Return the `ActiveRecord::Relation` instance
          #
          def records
            criteria = klass.where(:id.in => @ids)

            criteria.instance_exec(response['hits']['hits']) do |hits|
              define_singleton_method :to_a do
                self.entries.sort_by { |e| hits.index { |hit| hit['_id'] == e.id.to_s } }
              end
            end

            criteria
          end

          # Intercept call to sorting methods, so we can ignore the order from Elasticsearch
          #
          %w| asc desc order_by |.each do |name|
            define_method name do |*args|
              criteria = records.__send__ name, *args
              criteria.instance_exec do
                define_singleton_method(:to_a) { self.entries }
              end

              criteria
            end
          end
        end

      end

    end
  end
end
