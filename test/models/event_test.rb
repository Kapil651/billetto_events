require "test_helper"

class EventTest < ActiveSupport::TestCase
  def valid_billetto_event(overrides = {})
    {
      "id" => "evt_123",
      "object" => "event",
      "name" => "Summer Concert",
      "state" => "published",
      "kind" => "regular",
      "public" => true,
      "online_event" => false
    }.merge(overrides)
  end

  test "upsert_from_billetto! creates a new event" do
    event = Event.upsert_from_billetto!(valid_billetto_event)

    assert event.persisted?
    assert_equal "evt_123", event.billetto_id
    assert_equal "Summer Concert", event.name
    assert_equal "published", event.state
    assert_equal "regular", event.kind
    assert event.public
    assert_not event.online_event
    assert_equal valid_billetto_event, event.raw_payload
  end

  test "upsert_from_billetto! updates an existing event" do
    Event.upsert_from_billetto!(valid_billetto_event)

    updated = Event.upsert_from_billetto!(
      valid_billetto_event("name" => "Updated Concert", "state" => "completed")
    )

    assert_equal 1, Event.count
    assert_equal "Updated Concert", updated.name
    assert_equal "completed", updated.state
  end

  test "upsert_from_billetto! raises on invalid api data" do
    assert_raises(Billetto::ValidationError) do
      Event.upsert_from_billetto!({ "object" => "event" })
    end

    assert_equal 0, Event.count
  end

  test "validates state inclusion" do
    event = Event.new(billetto_id: "evt_1", state: "invalid", raw_payload: {})

    assert_not event.valid?
    assert_includes event.errors[:state], "is not included in the list"
  end

  test "validates kind inclusion" do
    event = Event.new(billetto_id: "evt_1", kind: "invalid", raw_payload: {})

    assert_not event.valid?
    assert_includes event.errors[:kind], "is not included in the list"
  end

  test "validates billetto_id presence and uniqueness" do
    Event.upsert_from_billetto!(valid_billetto_event)

    duplicate = Event.new(billetto_id: "evt_123", raw_payload: {})

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:billetto_id], "has already been taken"
  end
end
