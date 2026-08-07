require "application_system_test_case"

class AuthenticationSystemTest < ApplicationSystemTestCase
  test "visitor can open sign up page" do
    visit sign_up_path

    assert_selector "h1", text: "Create account"
    assert_selector "#clerk-sign-up"
    assert_link "Sign in", href: sign_in_path
  end

  test "visitor can open sign in page" do
    visit sign_in_path

    assert_selector "h1", text: "Sign in"
    assert_selector "#clerk-sign-in"
    assert_link "Create an account", href: sign_up_path
  end

  test "visitor can open sign out page" do
    visit sign_out_path

    assert_selector "h1", text: "Signing out"
  end

  test "navigation shows sign in and sign up for guests" do
    visit root_path

    assert_link "Sign in", href: sign_in_path
    assert_link "Sign up", href: sign_up_path
    assert_no_text "Sign out"
  end

  test "navigation shows sign out for authenticated test users" do
    visit root_path
    page.driver.browser.manage.add_cookie(name: "test_user_id", value: "browser_user", path: "/")
    visit root_path

    assert_link "Sign out", href: sign_out_path
    assert_no_link "Sign in", href: sign_in_path
  end
end
