require 'test_helper'

class SearchControllerTest < ActionController::TestCase
  setup do
    IndexManager.create_index force: true
  end

  test "should get suggest" do
    get :suggest, term: 'foo'
    assert_response :success
  end
end
