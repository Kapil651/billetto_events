require "test_helper"

class EventVoteTest < ActiveSupport::TestCase
  def setup
    @event = create_event!
  end

  test "requires user_id" do
    vote = EventVote.new(event: @event, vote_type: EventVote::UPVOTE)

    assert_not vote.valid?
    assert_includes vote.errors[:user_id], "can't be blank"
  end

  test "requires vote_type" do
    vote = EventVote.new(event: @event, user_id: "user_1")

    assert_not vote.valid?
    assert_includes vote.errors[:vote_type], "can't be blank"
  end

  test "restricts vote_type to up or down" do
    vote = EventVote.new(event: @event, user_id: "user_1", vote_type: "maybe")

    assert_not vote.valid?
    assert_includes vote.errors[:vote_type], "is not included in the list"
  end

  test "allows one vote per user per event" do
    EventVote.create!(event: @event, user_id: "user_1", vote_type: EventVote::UPVOTE)

    duplicate = EventVote.new(event: @event, user_id: "user_1", vote_type: EventVote::DOWNVOTE)

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:user_id], "has already been taken"
  end
end
