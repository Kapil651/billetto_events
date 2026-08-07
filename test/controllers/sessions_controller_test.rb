require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  test "sign in page renders" do
    get sign_in_path

    assert_response :success
    assert_select "h1", text: "Sign in"
    assert_select "#clerk-sign-in"
  end

  test "sign up page renders" do
    get sign_up_path

    assert_response :success
    assert_select "h1", text: "Create account"
    assert_select "#clerk-sign-up"
  end

  test "sign out page renders" do
    get sign_out_path

    assert_response :success
    assert_select "h1", text: "Signing out"
  end
end
