# Licensed to Elasticsearch B.V. under one or more contributor
# license agreements. See the NOTICE file distributed with
# this work for additional information regarding copyright
# ownership. Elasticsearch B.V. licenses this file to you under
# the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

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
