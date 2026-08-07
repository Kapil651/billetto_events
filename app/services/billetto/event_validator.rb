module Billetto
  class EventValidator
    EVENT_OBJECT = "event"
    EVENT_STATES = %w[draft published publishing completed canceled deleted].freeze
    EVENT_KINDS = %w[regular subscription recurring scheduled].freeze

    def self.validate!(event)
      new(event).validate!
    end

    def initialize(event)
      @event = event
      @details = []
    end

    def validate!
      unless event.is_a?(Hash)
        raise Billetto::ValidationError.new("Event must be a hash", details: [ "expected Hash, got #{event.class}" ])
      end

      normalize_id!

      validate_presence!("id", event["id"])
      validate_string!("id", event["id"])
      validate_presence!("object", event["object"])
      validate_inclusion!("object", event["object"], [ EVENT_OBJECT ])
      validate_string!("name", event["name"]) if event.key?("name")
      validate_inclusion!("state", event["state"], EVENT_STATES) if event.key?("state")
      validate_inclusion!("kind", event["kind"], EVENT_KINDS) if event.key?("kind")
      validate_boolean!("public", event["public"]) if event.key?("public")
      validate_boolean!("online_event", event["online_event"]) if event.key?("online_event")

      raise Billetto::ValidationError.new("Invalid event data", details: details) if details.any?

      event
    end

    private

    attr_reader :event, :details

    def normalize_id!
      return if event["id"].blank?

      event["id"] = event["id"].to_s
    end

    def validate_presence!(field, value)
      return if value.present?

      details << "#{field} is required"
    end

    def validate_string!(field, value)
      return if value.is_a?(String)

      details << "#{field} must be a string"
    end

    def validate_boolean!(field, value)
      return if [ true, false ].include?(value)

      details << "#{field} must be a boolean"
    end

    def validate_inclusion!(field, value, allowed_values)
      return if allowed_values.include?(value)

      details << "#{field} must be one of: #{allowed_values.join(', ')}"
    end
  end
end
