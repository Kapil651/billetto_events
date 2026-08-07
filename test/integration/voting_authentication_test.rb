require "test_helper"

class VotingAuthenticationTest < ActionDispatch::IntegrationTest
  def setup
    @event = create_event!(name: "Auth Test Event")
  end

  test "guests are redirected when attempting to vote" do
    post event_vote_path(@event), params: { vote_type: "up" }

    assert_redirected_to sign_in_path
    assert_equal 0, EventVote.count
    assert_equal 0, @event.reload.upvotes_count
  end

  test "guests see sign in prompt instead of vote buttons on events page" do
    get events_path

    assert_response :success
    assert_match "Sign in", response.body
    assert_match "to vote on this event", response.body
    assert_no_match 'value="Like"', response.body
  end

  test "authenticated users can vote" do
    sign_in_as("user_auth_test")

    assert_difference -> { EventVote.count }, 1 do
      post event_vote_path(@event), params: { vote_type: "up" }
    end

    assert_redirected_to events_path
    assert_equal EventVote::UPVOTE, EventVote.last.vote_type
    assert_equal "user_auth_test", EventVote.last.user_id
    assert_equal 1, @event.reload.upvotes_count
  end

  test "authenticated users see vote buttons on events page" do
    sign_in_as("user_auth_test")

    get events_path

    assert_response :success
    assert_select "button", text: "Like"
    assert_select "button", text: "Dislike"
  end
end
