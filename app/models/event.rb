class Event < ApplicationRecord
  validates :billetto_id, presence: true, uniqueness: true
  validates :state, inclusion: { in: Billetto::EventValidator::EVENT_STATES }, allow_nil: true
  validates :kind, inclusion: { in: Billetto::EventValidator::EVENT_KINDS }, allow_nil: true
  validates :raw_payload, presence: true

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
end
