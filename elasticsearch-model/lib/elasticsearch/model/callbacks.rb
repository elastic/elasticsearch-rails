# Licensed to Elasticsearch B.V. under one or more contributor
# license agreements. See the NOTICE file distributed with
# this work for additional information regarding copyright
# ownership. Elasticsearch B.V. licenses this file to you under
# the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#	http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

module Elasticsearch
  module Model

    # Allows to automatically update index based on model changes,
    # by hooking into the model lifecycle.
    #
    # @note A blocking HTTP request is done during the update process.
    #       If you need a more performant/resilient way of updating the index,
    #       consider adapting the callbacks behaviour, and use a background
    #       processing solution such as [Sidekiq](http://sidekiq.org)
    #       or [Resque](https://github.com/resque/resque).
    #
    module Callbacks

      # When included in a model, automatically injects the callback subscribers (`after_save`, etc)
      #
      # @example Automatically update Elasticsearch index when the model changes
      #
      #     class Article
      #       include Elasticsearch::Model
      #       include Elasticsearch::Model::Callbacks
      #     end
      #
      #     Article.first.update_attribute :title, 'Updated'
      #     #  SQL (0.3ms)  UPDATE "articles" SET "title" = ...
      #     #  2013-11-20 15:08:52 +0100: POST http://localhost:9200/articles/article/1/_update ...
      #
      def self.included(base)
        adapter = Adapter.from_class(base)
        base.__send__ :include, adapter.callbacks_mixin
      end

    end
  end
end
