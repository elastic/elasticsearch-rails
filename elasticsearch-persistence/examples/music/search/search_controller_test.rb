require 'test_helper'

class SearchControllerTest < ActionController::TestCase
  test "should get suggest" do
    get :suggest
    assert_response :success
  end

end
