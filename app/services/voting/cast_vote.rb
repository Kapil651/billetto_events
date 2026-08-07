module Voting
  class CastVote
    class Error < StandardError; end

    def initialize(event_store: Rails.configuration.event_store)
      @event_store = event_store
    end

    def upvote(event_id:, user_id:)
      publish(
        Voting::EventUpvoted.new(
          data: {
            event_id: event_id,
            user_id: user_id
          },
          metadata: traceability_metadata(event_id:, user_id:)
        ),
        event_id: event_id
      )
    end

    def downvote(event_id:, user_id:)
      publish(
        Voting::EventDownvoted.new(
          data: {
            event_id: event_id,
            user_id: user_id
          },
          metadata: traceability_metadata(event_id:, user_id:)
        ),
        event_id: event_id
      )
    end

    private

    attr_reader :event_store

    def publish(domain_event, event_id:)
      raise Error, "User ID is required" if domain_event.data[:user_id].blank?

      event_store.publish(domain_event, stream_name: stream_name(event_id))
    end

    def traceability_metadata(event_id:, user_id:)
      {
        user_id: user_id,
        event_id: event_id
      }
    end

    def stream_name(event_id)
      "Event$#{event_id}"
    end
  end
end
