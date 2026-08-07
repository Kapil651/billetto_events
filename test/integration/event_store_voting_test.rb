require "test_helper"

class EventStoreVotingTest < ActionDispatch::IntegrationTest
  def setup
    @event_store = Rails.configuration.event_store
    @event = create_event!(name: "RES Voting Event")
    @user_id = "user_res_voting"
    sign_in_as(@user_id)
  end

  test "upvote publishes EventUpvoted and updates counters through the full stack" do
    post event_vote_path(@event), params: { vote_type: "up" }

    stored_events = @event_store.read.stream("Event$#{@event.id}").to_a
    vote = EventVote.find_by!(event: @event, user_id: @user_id)

    assert_equal 1, stored_events.size
    assert_instance_of Voting::EventUpvoted, stored_events.first
    assert_equal @event.id, stored_events.first.data[:event_id]
    assert_equal @user_id, stored_events.first.data[:user_id]
    assert_equal @user_id, stored_events.first.metadata[:user_id]
    assert_equal EventVote::UPVOTE, vote.vote_type
    assert_equal 1, @event.reload.upvotes_count
    assert_equal 0, @event.downvotes_count
  end

  test "downvote publishes EventDownvoted and updates counters" do
    post event_vote_path(@event), params: { vote_type: "down" }

    stored_events = @event_store.read.stream("Event$#{@event.id}").to_a

    assert_instance_of Voting::EventDownvoted, stored_events.last
    assert_equal 1, @event.reload.downvotes_count
  end

  test "switching vote publishes multiple events and keeps counts accurate" do
    post event_vote_path(@event), params: { vote_type: "up" }
    post event_vote_path(@event), params: { vote_type: "down" }

    stored_events = @event_store.read.stream("Event$#{@event.id}").to_a

    assert_equal 2, stored_events.size
    assert_instance_of Voting::EventUpvoted, stored_events.first
    assert_instance_of Voting::EventDownvoted, stored_events.last
    assert_equal EventVote::DOWNVOTE, EventVote.find_by!(event: @event, user_id: @user_id).vote_type
    assert_equal 0, @event.reload.upvotes_count
    assert_equal 1, @event.downvotes_count
  end

  test "duplicate vote does not inflate counters" do
    2.times { post event_vote_path(@event), params: { vote_type: "up" } }

    assert_equal 2, @event_store.read.stream("Event$#{@event.id}").to_a.size
    assert_equal 1, EventVote.where(event: @event, user_id: @user_id).count
    assert_equal 1, @event.reload.upvotes_count
  end

  test "events page displays updated vote totals" do
    post event_vote_path(@event), params: { vote_type: "up" }

    get events_path

    assert_response :success
    assert_select ".event-card__vote-count--up", text: /▲ 1/
    assert_select ".event-card__vote-count--down", text: /▼ 0/
    assert_select ".event-card__vote-score", text: /Score: 1/
  end
end
