module Elasticsearch
  module Model
    module Response

      # Pagination for search results/records
      #
      module Pagination
        # Allow models to be paginated with the "kaminari" gem [https://github.com/amatsuda/kaminari]
        #
        module Kaminari
          def self.included(base)
            # Include the Kaminari configuration and paging method in response
            #
            base.__send__ :include, ::Kaminari::ConfigurationMethods::ClassMethods
            base.__send__ :include, ::Kaminari::PageScopeMethods

            # Include the Kaminari paging methods in results and records
            #
            Elasticsearch::Model::Response::Results.__send__ :include, ::Kaminari::ConfigurationMethods::ClassMethods
            Elasticsearch::Model::Response::Results.__send__ :include, ::Kaminari::PageScopeMethods
            Elasticsearch::Model::Response::Records.__send__ :include, ::Kaminari::PageScopeMethods

            Elasticsearch::Model::Response::Results.__send__ :delegate, :limit_value, :offset_value, :total_count, to: :response
            Elasticsearch::Model::Response::Records.__send__ :delegate, :limit_value, :offset_value, :total_count, to: :response

            base.class_eval <<-RUBY, __FILE__, __LINE__ + 1
              # Define the `page` Kaminari method
              #
              def #{::Kaminari.config.page_method_name}(num=nil)
                @results  = nil
                @records  = nil
                @response = nil
                @page     = [num.to_i, 1].max
                @per_page ||= klass.default_per_page

                self.search.definition.update size: @per_page,
                                              from: @per_page * (@page - 1)

                self
              end
            RUBY
          end

          # Returns the current "limit" (`size`) value
          #
          def limit_value
            case
              when search.definition[:size]
                search.definition[:size]
              else
                search.klass.default_per_page
            end
          end

          # Returns the current "offset" (`from`) value
          #
          def offset_value
            case
              when search.definition[:from]
                search.definition[:from]
              else
                0
            end
          end

          # Set the "limit" (`size`) value
          #
          def limit(value)
            @results  = nil
            @records  = nil
            @response = nil
            @per_page = value

            search.definition.update :size => @per_page
            search.definition.update :from => @per_page * (@page - 1) if @page
            self
          end

          # Set the "offset" (`from`) value
          #
          def offset(value)
            @results  = nil
            @records  = nil
            @response = nil
            @page     = nil
            search.definition.update :from => value
            self
          end

          # Returns the total number of results
          #
          def total_count
            results.total
          end
        end
      end

    end
  end
end
