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
      "online_event" => false,
      "starts_at" => "2026-08-15T19:30:00.000Z"
    }.merge(overrides)
  end

  test "requires billetto_id" do
    event = Event.new(name: "Concert", raw_payload: { "object" => "event" })

    assert_not event.valid?
    assert_includes event.errors[:billetto_id], "can't be blank"
  end

  test "requires raw_payload" do
    event = Event.new(billetto_id: "evt_1", name: "Concert")

    assert_not event.valid?
    assert_includes event.errors[:raw_payload], "can't be blank"
  end

  test "validates state inclusion" do
    event = Event.new(billetto_id: "evt_1", state: "invalid", raw_payload: { "object" => "event" })

    assert_not event.valid?
    assert_includes event.errors[:state], "is not included in the list"
  end

  test "validates kind inclusion" do
    event = Event.new(billetto_id: "evt_1", kind: "invalid", raw_payload: { "object" => "event" })

    assert_not event.valid?
    assert_includes event.errors[:kind], "is not included in the list"
  end

  test "validates billetto_id uniqueness" do
    create_event!(billetto_id: "evt_unique", name: "First")

    duplicate = Event.new(billetto_id: "evt_unique", name: "Second", raw_payload: { "object" => "event" })

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:billetto_id], "has already been taken"
  end

  test "title uses name when present" do
    event = Event.new(name: "Jazz Night", billetto_id: "evt_1", raw_payload: {})

    assert_equal "Jazz Night", event.title
  end

  test "title falls back when name is blank" do
    event = Event.new(name: nil, billetto_id: "evt_1", raw_payload: {})

    assert_equal "Untitled Event", event.title
  end

  test "accepts valid starts_at in raw_payload" do
    event = Event.new(
      billetto_id: "evt_date",
      name: "Dated Event",
      raw_payload: { "starts_at" => "2026-10-01T18:00:00.000Z" }
    )

    assert event.valid?
    assert_equal Time.zone.parse("2026-10-01T18:00:00.000Z"), event.starts_at
  end

  test "rejects invalid starts_at in raw_payload" do
    event = Event.new(
      billetto_id: "evt_bad_date",
      name: "Bad Date Event",
      raw_payload: { "starts_at" => "not-a-date" }
    )

    assert_not event.valid?
    assert_includes event.errors[:raw_payload], "contains an invalid starts_at date"
  end

  test "allows missing starts_at in raw_payload" do
    event = Event.new(
      billetto_id: "evt_no_date",
      name: "Undated Event",
      raw_payload: { "object" => "event" }
    )

    assert event.valid?
    assert_nil event.starts_at
    assert_equal "Date to be announced", event.formatted_date
  end

  test "upsert_from_billetto! creates and updates events" do
    event = Event.upsert_from_billetto!(valid_billetto_event)

    assert event.persisted?
    assert_equal "Summer Concert", event.name

    updated = Event.upsert_from_billetto!(valid_billetto_event("name" => "Updated Concert"))

    assert_equal 1, Event.count
    assert_equal "Updated Concert", updated.name
  end

  test "upsert_from_billetto! raises on invalid api data" do
    assert_raises(Billetto::ValidationError) do
      Event.upsert_from_billetto!({ "object" => "event" })
    end
  end

  test "score reflects vote counters" do
    event = create_event!(upvotes_count: 4, downvotes_count: 1)

    assert_equal 3, event.score
  end
end
