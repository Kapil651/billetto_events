require "application_system_test_case"

class VotingSystemTest < ApplicationSystemTestCase
  def setup
    @event = create_event!(name: "Browser Vote Event")
  end

  test "guest sees sign in prompt and cannot vote" do
    visit events_path

    assert_text "Sign in to vote on this event"
    assert_no_button "Like"
    assert_no_button "Dislike"
  end

  test "authenticated user can vote from the browser" do
    visit root_path
    page.driver.browser.manage.add_cookie(name: "test_user_id", value: "browser_voter", path: "/")

    visit events_path

    assert_button "Like"
    assert_button "Dislike"
    assert_text "▲ 0"
    assert_text "▼ 0"

    click_button "Like"

    assert_text "▲ 1"
    assert_text "▼ 0"
    assert_text "Score: 1"
  end

  test "authenticated user can switch from like to dislike" do
    visit root_path
    page.driver.browser.manage.add_cookie(name: "test_user_id", value: "browser_switcher", path: "/")

    visit events_path
    click_button "Like"
    click_button "Dislike"

    assert_text "▲ 0"
    assert_text "▼ 1"
    assert_text "Score: -1"
  end
end
