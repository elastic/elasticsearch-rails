require 'test_helper'

module Elasticsearch
  module Model
    class ActiveRecordCustomSerializationTest < Elasticsearch::Test::IntegrationTestCase

      class ::ArticleWithCustomSerialization < ActiveRecord::Base
        include Elasticsearch::Model
        include Elasticsearch::Model::Callbacks

        mapping do
          indexes :title
        end

        def as_indexed_json(options={})
          as_json(options.merge root: false).slice('title')
        end
      end

      context "ActiveRecord model with custom JSON serialization" do
        setup do
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


      class ::ArticleWithCustomSerializationMethod < ActiveRecord::Base
        include Elasticsearch::Model
        include Elasticsearch::Model::Callbacks

        mapping do
          indexes :tag_list
        end

        def tag_list=(val)
          attribute_will_change!('tag_list') unless val == @tag_list
          @tag_list=val
        end

        def tag_list
          @tag_list || 'foo bar'
        end

        def as_indexed_json(options={})
          as_json(root: false, methods: [:tag_list])
        end
      end

      context "ActiveRecord model with custom JSON serialization including method" do
        setup do
          ActiveRecord::Schema.define(:version => 1) do
            create_table ArticleWithCustomSerializationMethod.table_name do |t|
              t.string   :title
            end
          end

          ArticleWithCustomSerializationMethod.delete_all
          ArticleWithCustomSerializationMethod.__elasticsearch__.create_index! force: true
        end

        should "index the tag_list method when creating" do
          ArticleWithCustomSerializationMethod.create! title: 'Test'

          a = ArticleWithCustomSerializationMethod.__elasticsearch__.client.get \
                index: 'article_with_custom_serialization_methods',
                type:  'article_with_custom_serialization_method',
                id:    '1'

          assert_equal( { 'id'=> 1, 'title'=> 'Test', 'tag_list' => 'foo bar' }, a['_source'] )
        end

        should "index the updated tag_list attribute when updating" do
          ArticleWithCustomSerializationMethod.create! title: 'Test'

          article = ArticleWithCustomSerializationMethod.first
          article.tag_list='UPDATED'
          article.save!

          a = ArticleWithCustomSerializationMethod.__elasticsearch__.client.get \
                index: 'article_with_custom_serialization_methods',
                type:  'article_with_custom_serialization_method',
                id:    '1'

          assert_equal( { 'id'=> 1, 'title'=> 'Test', 'tag_list' => 'UPDATED' }, a['_source'] )
        end
      end

    end
  end
end
