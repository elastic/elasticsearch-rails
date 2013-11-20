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
