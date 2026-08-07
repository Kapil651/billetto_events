require "test_helper"

class Voting::EventVoteProjectorTest < ActiveSupport::TestCase
  def setup
    @event = Event.create!(
      billetto_id: "evt_projector_test",
      name: "Projector Test Event",
      raw_payload: { "id" => "evt_projector_test", "object" => "event" }
    )
    @projector = Voting::EventVoteProjector.new
  end

  test "creates an upvote record and increments counter" do
    @projector.call(
      Voting::EventUpvoted.new(data: { event_id: @event.id, user_id: "user_1" })
    )

    vote = EventVote.find_by!(event_id: @event.id, user_id: "user_1")

    assert_equal EventVote::UPVOTE, vote.vote_type
    assert_equal 1, @event.reload.upvotes_count
    assert_equal 0, @event.downvotes_count
  end

  test "switches from downvote to upvote" do
    @projector.call(
      Voting::EventDownvoted.new(data: { event_id: @event.id, user_id: "user_1" })
    )
    @projector.call(
      Voting::EventUpvoted.new(data: { event_id: @event.id, user_id: "user_1" })
    )

    vote = EventVote.find_by!(event_id: @event.id, user_id: "user_1")

    assert_equal EventVote::UPVOTE, vote.vote_type
    assert_equal 1, @event.reload.upvotes_count
    assert_equal 0, @event.downvotes_count
  end

  test "ignores duplicate vote of the same type" do
    event = Voting::EventUpvoted.new(data: { event_id: @event.id, user_id: "user_1" })

    @projector.call(event)
    @projector.call(event)

    assert_equal 1, EventVote.where(event_id: @event.id, user_id: "user_1").count
    assert_equal 1, @event.reload.upvotes_count
  end
end
