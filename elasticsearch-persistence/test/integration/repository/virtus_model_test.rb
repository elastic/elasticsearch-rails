require 'test_helper'

require 'virtus'

module Elasticsearch
  module Persistence
    class RepositoryWithVirtusIntegrationTest < Elasticsearch::Test::IntegrationTestCase

      class ::Page
        include Virtus.model

        attribute :title,     String
        attribute :views,     Integer, default: 0
        attribute :published, Boolean, default: false
        attribute :slug,      String,  default: lambda { |page, attribute| page.title.downcase.gsub(' ', '-') }
      end

      context "The repository with a Virtus model" do
        setup do
          @repository = Elasticsearch::Persistence::Repository.new do
            index :pages
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
      end

    end
  end
end
