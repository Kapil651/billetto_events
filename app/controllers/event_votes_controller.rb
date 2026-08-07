class EventVotesController < ApplicationController
  before_action :require_clerk_session!
  before_action :set_event

  def create
    Voting::CastVote.new.public_send(vote_action, event_id: @event.id, user_id: clerk.user_id)

    redirect_to events_path, notice: vote_notice
  rescue Voting::CastVote::Error, ActiveRecord::RecordNotFound => error
    redirect_to events_path, alert: error.message
  end

  private

  def set_event
    @event = Event.find(params[:event_id])
  end

  def vote_action
    params.require(:vote_type) == "down" ? :downvote : :upvote
  end

  def vote_notice
    vote_action == :downvote ? "Downvote recorded." : "Upvote recorded."
  end
end
