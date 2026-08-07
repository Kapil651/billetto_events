module Voting
  class EventVoteProjector
    UPVOTE = "up"
    DOWNVOTE = "down"

    def call(event)
      event_id = event.data.fetch(:event_id)
      user_id = event.data.fetch(:user_id)
      new_vote_type = event.is_a?(Voting::EventUpvoted) ? UPVOTE : DOWNVOTE

      EventVote.transaction do
        event_record = Event.lock.find(event_id)
        vote = EventVote.find_or_initialize_by(event_id: event_record.id, user_id: user_id)
        previous_vote_type = vote.vote_type

        if vote.new_record?
          vote.vote_type = new_vote_type
          vote.save!
          increment_counter(event_record, new_vote_type)
        elsif previous_vote_type != new_vote_type
          vote.update!(vote_type: new_vote_type)
          decrement_counter(event_record, previous_vote_type)
          increment_counter(event_record, new_vote_type)
        end
      end
    end

    private

    def increment_counter(event_record, vote_type)
      if vote_type == UPVOTE
        event_record.increment!(:upvotes_count)
      else
        event_record.increment!(:downvotes_count)
      end
    end

    def decrement_counter(event_record, vote_type)
      if vote_type == UPVOTE
        event_record.decrement!(:upvotes_count) if event_record.upvotes_count.positive?
      elsif event_record.downvotes_count.positive?
        event_record.decrement!(:downvotes_count)
      end
    end
  end
end
