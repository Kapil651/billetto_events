module Billetto
  class EventsFetcher
    EVENTS_PATH = "/api/v3/organiser/events"

    def initialize(client: Client.new)
      @client = client
    end

    def fetch_events(params: {})
      response = client.get(EVENTS_PATH, params)
      validate_list_response!(response)

      {
        events: response["data"].map { |event| EventValidator.validate!(event) },
        has_more: response.fetch("has_more"),
        next_url: response["next_url"],
        total: response["total"]
      }
    end

    def fetch_event(event_id)
      raise Billetto::ValidationError.new("Invalid event id", details: [ "event_id is required" ]) if event_id.blank?

      response = client.get("#{EVENTS_PATH}/#{event_id}")
      EventValidator.validate!(response)
    end

    def fetch_events_from_url(url)
      raise Billetto::ValidationError.new("Invalid pagination url", details: [ "url is required" ]) if url.blank?

      response = client.get_url(url)
      validate_list_response!(response)

      {
        events: response["data"].map { |event| EventValidator.validate!(event) },
        has_more: response.fetch("has_more"),
        next_url: response["next_url"],
        total: response["total"]
      }
    end

    private

    attr_reader :client

    def validate_list_response!(response)
      details = []
      details << "data must be an array" unless response["data"].is_a?(Array)
      details << "has_more must be a boolean" unless [ true, false ].include?(response["has_more"])
      details << "total must be an integer" unless response["total"].is_a?(Integer)

      return if details.empty?

      raise Billetto::ValidationError.new("Invalid events list response", details: details)
    end
  end
end
