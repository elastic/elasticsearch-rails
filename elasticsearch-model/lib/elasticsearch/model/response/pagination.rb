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
                @per_page ||= __default_per_page

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
                __default_per_page
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
            return self if value.to_i <= 0
            @results  = nil
            @records  = nil
            @response = nil
            @per_page = value.to_i

            search.definition.update :size => @per_page
            search.definition.update :from => @per_page * (@page - 1) if @page
            self
          end

          # Set the "offset" (`from`) value
          #
          def offset(value)
            return self if value.to_i < 0
            @results  = nil
            @records  = nil
            @response = nil
            @page     = nil
            search.definition.update :from => value.to_i
            self
          end

          # Returns the total number of results
          #
          def total_count
            results.total
          end

          # Returns the models's `per_page` value or the default
          #
          # @api private
          #
          def __default_per_page
            klass.respond_to?(:default_per_page) && klass.default_per_page || ::Kaminari.config.default_per_page
          end
        end

        # Allow models to be paginated with the "will_paginate" gem [https://github.com/mislav/will_paginate]
        #
        module WillPaginate
          def self.included(base)
            base.__send__ :include, ::WillPaginate::CollectionMethods

            # Include the paging methods in results and records
            #
            methods = [:current_page, :offset, :length, :per_page, :total_entries, :total_pages, :previous_page, :next_page, :out_of_bounds?]
            Elasticsearch::Model::Response::Results.__send__ :delegate, *methods, to: :response
            Elasticsearch::Model::Response::Records.__send__ :delegate, *methods, to: :response
          end

          def offset
            (current_page - 1) * per_page
          end

          def length
            search.definition[:size]
          end

          # Main pagination method
          #
          # @example
          #
          #     Article.search('foo').paginate(page: 1, per_page: 30)
          #
          def paginate(options)
            param_name = options[:param_name] || :page
            page       = [options[param_name].to_i, 1].max
            per_page   = (options[:per_page] || __default_per_page).to_i

            search.definition.update size: per_page,
                                     from: (page - 1) * per_page
            self
          end

          # Return the current page
          #
          def current_page
            search.definition[:from] / per_page + 1 if search.definition[:from] && per_page
          end

          # Pagination method
          #
          # @example
          #
          #     Article.search('foo').page(2)
          #
          def page(num)
            paginate(page: num, per_page: per_page) # shorthand
          end

          # Return or set the "size" value
          #
          # @example
          #
          #     Article.search('foo').per_page(15).page(2)
          #
          def per_page(num = nil)
            if num.nil?
              search.definition[:size]
            else
              paginate(page: current_page, per_page: num) # shorthand
            end
          end

          # Returns the total number of results
          #
          def total_entries
            results.total
          end

          # Returns the models's `per_page` value or the default
          #
          # @api private
          #
          def __default_per_page
            klass.respond_to?(:per_page) && klass.per_page || ::WillPaginate.per_page
          end
        end
      end

    end
  end
end
