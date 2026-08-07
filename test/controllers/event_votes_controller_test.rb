require "test_helper"

class EventVotesControllerTest < ActionController::TestCase
  tests EventVotesController

  def setup
    @event = Event.create!(
      billetto_id: "evt_controller_vote",
      name: "Controller Vote Event",
      raw_payload: { "id" => "evt_controller_vote", "object" => "event" }
    )
    @request.env["clerk"] = Clerk::Proxy.new(session_claims: { "sub" => "user_controller" })
  end

  test "creates upvote through event store" do
    assert_difference -> { EventVote.count }, 1 do
      post :create, params: { event_id: @event.id, vote_type: "up" }
    end

    assert_redirected_to events_path
    assert_equal EventVote::UPVOTE, EventVote.last.vote_type
    assert_equal 1, @event.reload.upvotes_count
  end

  test "creates downvote through event store" do
    post :create, params: { event_id: @event.id, vote_type: "down" }

    assert_equal EventVote::DOWNVOTE, EventVote.last.vote_type
    assert_equal 1, @event.reload.downvotes_count
  end

  test "redirects unauthenticated users" do
    @request.env["clerk"] = Clerk::Proxy.new

    post :create, params: { event_id: @event.id, vote_type: "up" }

    assert_redirected_to sign_in_path
  end
end
