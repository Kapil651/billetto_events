class Event < ApplicationRecord
  validates :billetto_id, presence: true, uniqueness: true
  validates :state, inclusion: { in: Billetto::EventValidator::EVENT_STATES }, allow_nil: true
  validates :kind, inclusion: { in: Billetto::EventValidator::EVENT_KINDS }, allow_nil: true
  validates :raw_payload, presence: true

  scope :by_start_date, -> {
    order(Arel.sql("(raw_payload->>'starts_at') ASC NULLS LAST"), created_at: :desc)
  }

  def self.upsert_from_billetto!(data)
    validated = Billetto::EventValidator.validate!(data)

    transaction do
      find_or_initialize_by(billetto_id: validated["id"]).tap do |event|
        event.assign_from_billetto(validated)
        event.save!
      end
    end
  end

  def assign_from_billetto(data)
    self.name = data["name"]
    self.state = data["state"]
    self.kind = data["kind"]
    self.public = data["public"]
    self.online_event = data["online_event"]
    self.raw_payload = data
  end

  def title
    name.presence || "Untitled Event"
  end

  def starts_at
    value = raw_payload["starts_at"]
    return if value.blank?

    Time.zone.parse(value)
  rescue ArgumentError, TypeError
    nil
  end

  def formatted_date
    return "Date to be announced" unless starts_at

    starts_at.strftime("%A, %B %-d, %Y · %-l:%M %p")
  end

  def image_url
    raw_payload["image_url"].presence
  end

  def description
    raw_payload["description"].to_s.strip
  end

  def brief_description(limit: 160)
    return "No description available." if description.blank?

    description.length > limit ? "#{description[0...limit].strip}..." : description
  end
end
