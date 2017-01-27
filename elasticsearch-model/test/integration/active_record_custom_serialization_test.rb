require 'test_helper'
require 'active_record'

# Needed for ActiveRecord 3.x ?
ActiveRecord::Base.establish_connection( :adapter => 'sqlite3', :database => ":memory:" ) unless ActiveRecord::Base.connected?

::ActiveRecord::Base.raise_in_transactional_callbacks = true if ::ActiveRecord::Base.respond_to?(:raise_in_transactional_callbacks) && ::ActiveRecord::VERSION::MAJOR.to_s < '5'

module Elasticsearch
  module Model
    class ActiveRecordCustomSerializationTest < Elasticsearch::Test::IntegrationTestCase
      context "ActiveRecord model with custom JSON serialization" do
        setup do
          class ::ArticleWithCustomSerialization < ActiveRecord::Base
            include Elasticsearch::Model
            include Elasticsearch::Model::Callbacks

            mapping do
              indexes :title
            end

            def as_indexed_json(options={})
              # as_json(options.merge root: false).slice('title')
              { title: self.title }
            end
          end

          ActiveRecord::Schema.define(:version => 1) do
            create_table ArticleWithCustomSerialization.table_name do |t|
              t.string   :title
              t.string   :status
            end
          end

          ArticleWithCustomSerialization.delete_all
          ArticleWithCustomSerialization.__elasticsearch__.create_index! force: true
        end

        should "index only the title attribute when creating" do
          ArticleWithCustomSerialization.create! title: 'Test', status: 'green'

          a = ArticleWithCustomSerialization.__elasticsearch__.client.get \
                index: 'article_with_custom_serializations',
                type:  'article_with_custom_serialization',
                id:    '1'

          assert_equal( { 'title' => 'Test' }, a['_source'] )
        end

        should "index only the title attribute when updating" do
          ArticleWithCustomSerialization.create! title: 'Test', status: 'green'

          article = ArticleWithCustomSerialization.first
          article.update_attributes title: 'UPDATED', status: 'red'

          a = ArticleWithCustomSerialization.__elasticsearch__.client.get \
                index: 'article_with_custom_serializations',
                type:  'article_with_custom_serialization',
                id:    '1'

          assert_equal( { 'title' => 'UPDATED' }, a['_source'] )
        end
      end

    end
  end
end
