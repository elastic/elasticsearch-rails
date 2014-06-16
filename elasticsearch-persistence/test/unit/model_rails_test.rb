require 'test_helper'

require 'elasticsearch/persistence/model'
require 'elasticsearch/persistence/model/rails'

require 'rails'
require 'action_controller/railtie'
require 'action_view/railtie'

class ::MyRailsModel
  include Elasticsearch::Persistence::Model
  include Elasticsearch::Persistence::Model::Rails

  attribute :name, String, mapping: { analyzer: 'string' }
  attribute :published_at, DateTime
  attribute :published_on, Date
end

class Application < Rails::Application
  config.eager_load = false
  config.root       = File.dirname(File.expand_path('../../../tmp', __FILE__))
  config.logger     = Logger.new($stderr)

  routes.append do
    resources :my_rails_models
  end
end

class ApplicationController < ActionController::Base
  include Application.routes.url_helpers
  include ActionController::UrlFor
end
ApplicationController.default_url_options = { host: 'localhost' }
ApplicationController._routes.append { resources :my_rails_models }

class MyRailsModelController < ApplicationController; end

Application.initialize!

class Elasticsearch::Persistence::ModelRailsTest < Test::Unit::TestCase
  context "The model in a Rails application" do

    should "generate proper URLs and paths" do
      model = MyRailsModel.new name: 'Test'
      model.stubs(:id).returns(1)
      model.stubs(:persisted?).returns(true)

      controller = MyRailsModelController.new
      controller.request = ActionDispatch::Request.new({})

      assert_equal 'http://localhost/my_rails_models/1', controller.url_for(model)
      assert_equal '/my_rails_models/1/edit',            controller.edit_my_rails_model_path(model)
    end

    should "generate a link" do
      class MyView; include ActionView::Helpers::UrlHelper; end

      model = MyRailsModel.new name: 'Test'
      view  = MyView.new
      view.expects(:url_for).with(model).returns('foo/bar')

      assert_equal '<a href="foo/bar">Show</a>', view.link_to('Show', model)
    end

    should "parse DateTime from Rails forms" do
      params = { "published_at(1i)"=>"2014",
                 "published_at(2i)"=>"1",
                 "published_at(3i)"=>"1",
                 "published_at(4i)"=>"12",
                 "published_at(5i)"=>"00"
                }

      m = MyRailsModel.new params
      assert_equal "2014-01-01T12:00:00+00:00", m.published_at.iso8601
    end

    should "parse Date from Rails forms" do
      params = { "published_on(1i)"=>"2014",
                 "published_on(2i)"=>"1",
                 "published_on(3i)"=>"1"
                }

      m = MyRailsModel.new params
      assert_equal "2014-01-01", m.published_on.iso8601
    end

  end
end
