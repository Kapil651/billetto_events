class EventsController < ApplicationController
  def index
    @events = Event.by_start_date
  end
end
