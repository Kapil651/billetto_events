require "test_helper"

class Voting::CastVoteTest < ActiveSupport::TestCase
  def setup
    @event_store = Rails.configuration.event_store
    @event = Event.create!(
      billetto_id: "evt_vote_test",
      name: "Vote Test Event",
      raw_payload: { "id" => "evt_vote_test", "object" => "event" }
    )
    @service = Voting::CastVote.new(event_store: @event_store)
  end

  test "upvote publishes EventUpvoted with user and event ids" do
    @service.upvote(event_id: @event.id, user_id: "user_abc")

    stored_events = @event_store.read.stream("Event$#{@event.id}").to_a

    assert_equal 1, stored_events.size
    assert_instance_of Voting::EventUpvoted, stored_events.first
    assert_equal @event.id, stored_events.first.data[:event_id]
    assert_equal "user_abc", stored_events.first.data[:user_id]
    assert_equal "user_abc", stored_events.first.metadata[:user_id]
  end

  test "downvote publishes EventDownvoted with user and event ids" do
    @service.downvote(event_id: @event.id, user_id: "user_xyz")

    stored_events = @event_store.read.stream("Event$#{@event.id}").to_a

    assert_equal 1, stored_events.size
    assert_instance_of Voting::EventDownvoted, stored_events.first
    assert_equal @event.id, stored_events.first.data[:event_id]
    assert_equal "user_xyz", stored_events.first.data[:user_id]
  end

  test "requires a user id" do
    assert_raises(Voting::CastVote::Error) do
      @service.upvote(event_id: @event.id, user_id: nil)
    end
  end
end
