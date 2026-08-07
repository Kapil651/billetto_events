class EventVote < ApplicationRecord
  UPVOTE = "up"
  DOWNVOTE = "down"

  belongs_to :event

  validates :user_id, presence: true
  validates :vote_type, presence: true, inclusion: { in: [ UPVOTE, DOWNVOTE ] }
  validates :user_id, uniqueness: { scope: :event_id }
end
