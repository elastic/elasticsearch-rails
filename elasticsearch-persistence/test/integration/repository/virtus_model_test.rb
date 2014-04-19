require 'test_helper'

require 'virtus'

module Elasticsearch
  module Persistence
    class RepositoryWithVirtusIntegrationTest < Elasticsearch::Test::IntegrationTestCase

      class ::Page
        include Virtus.model

        attribute :id,        String, writer: :private
        attribute :title,     String
        attribute :views,     Integer, default: 0
        attribute :published, Boolean, default: false
        attribute :slug,      String,  default: lambda { |page, attr| page.title.downcase.gsub(' ', '-') }

        def set_id(id)
          self.id = id
        end
      end

      context "The repository with a Virtus model" do
        setup do
          @repository = Elasticsearch::Persistence::Repository.new do
            index :pages
            klass Page

            def deserialize(document)
              page = klass.new document['_source']
              page.set_id document['_id']
              page
            end
          end
        end

        should "save and find the object" do
          page = Page.new title: 'Test Page'

          response = @repository.save page
          id = response['_id']

          result = @repository.find(id)

          assert_instance_of Page,  result
          assert_equal 'Test Page', result.title
          assert_equal 0,           result.views

          assert_not_nil Elasticsearch::Persistence.client.get index: 'pages',
                                                               type: 'page',
                                                               id: id
        end

        should "update the object with a partial document" do
          response = @repository.save Page.new(title: 'Test')
          id = response['_id']

          page = @repository.find(id)

          assert_equal 'Test', page.title

          @repository.update page.id, doc: { title: 'UPDATE' }

          page = @repository.find(id)
          assert_equal 'UPDATE', page.title
        end

        should "update the object with a Hash" do
          response = @repository.save Page.new(title: 'Test')
          id = response['_id']

          page = @repository.find(id)

          assert_equal 'Test', page.title

          @repository.update id: page.id, title: 'UPDATE'

          page = @repository.find(id)
          assert_equal 'UPDATE', page.title
        end

        should "update the object with a script" do
          response = @repository.save Page.new(title: 'Test Page')
          id = response['_id']

          page = @repository.find(id)

          assert_not_nil page.id
          assert_equal 0, page.views

          @repository.update page.id, script: 'ctx._source.views += 1'

          page = @repository.find(id)
          assert_equal 1, page.views

          @repository.update id: page.id, script: 'ctx._source.views += 1'

          page = @repository.find(id)
          assert_equal 2, page.views
        end

        should "update the object with a script and params" do
          response = @repository.save Page.new(title: 'Test Page')

          @repository.update id: response['_id'], script: 'ctx._source.views += count', params: { count: 3 }

          page = @repository.find(response['_id'])
          assert_equal 3, page.views
        end
      end

    end
  end
end
