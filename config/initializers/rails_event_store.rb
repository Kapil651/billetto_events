Rails.configuration.to_prepare do
  Rails.configuration.event_store = event_store = RailsEventStore::JSONClient.new

  event_store.subscribe(
    Voting::EventVoteProjector.new,
    to: [ Voting::EventUpvoted, Voting::EventDownvoted ]
  )
end
