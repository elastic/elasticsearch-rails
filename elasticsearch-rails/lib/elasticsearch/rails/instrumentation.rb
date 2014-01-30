require 'elasticsearch/rails/instrumentation/railtie'
require 'elasticsearch/rails/instrumentation/publishers'

module Elasticsearch
  module Rails

    # This module adds support for displaying statistics about search duration in the Rails application log
    # by integrating with the `ActiveSupport::Notifications` framework and `ActionController` logger.
    #
    # == Usage
    #
    # Require the component in your `application.rb` file:
    #
    #     require 'elasticsearch/rails/instrumentation'
    #
    # You should see an output like this in your application log in development environment:
    #
    #     Article Search (321.3ms) { index: "articles", type: "article", body: { query: ... } }
    #
    # Also, the total duration of the request to Elasticsearch is displayed in the Rails request breakdown:
    #
    #     Completed 200 OK in 615ms (Views: 230.9ms | ActiveRecord: 0.0ms | Elasticsearch: 321.3ms)
    #
    # @note The displayed duration includes the HTTP transfer -- the time it took Elasticsearch
    #       to process your request is available in the `response.took` property.
    #
    # @see Elasticsearch::Rails::Instrumentation::Publishers
    # @see Elasticsearch::Rails::Instrumentation::Railtie
    #
    # @see http://api.rubyonrails.org/classes/ActiveSupport/Notifications.html
    #
    #
    module Instrumentation
    end
  end
end
