require 'test_helper'

require 'elasticsearch/persistence/model'

require 'rails'
require 'action_controller/railtie'
require 'action_view/railtie'

class ::MyRailsModel
  include Elasticsearch::Persistence::Model
  attribute :name, String, mapping: { analyzer: 'string' }
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

  end
end
