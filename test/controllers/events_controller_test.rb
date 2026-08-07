require "test_helper"

class EventsControllerTest < ActionDispatch::IntegrationTest
  test "index lists events with title, date, and description" do
    Event.create!(
      billetto_id: "evt_showcase",
      name: "Jazz Night",
      state: "published",
      raw_payload: {
        "id" => "evt_showcase",
        "object" => "event",
        "name" => "Jazz Night",
        "state" => "published",
        "description" => "An evening of live jazz with local musicians.",
        "starts_at" => "2026-09-15T19:30:00.000Z",
        "image_url" => "https://example.com/jazz.jpg"
      }
    )

    get root_path

    assert_response :success
    assert_select "h1", text: "Upcoming Events"
    assert_select ".event-card", count: 1
    assert_select ".event-card__title", text: "Jazz Night"
    assert_match "An evening of live jazz", response.body
    assert_match "https://example.com/jazz.jpg", response.body
    assert_select ".event-card__vote-count--up", text: /▲ 0/
    assert_select ".event-card__vote-count--down", text: /▼ 0/
  end

  test "index shows empty state when no events exist" do
    get events_path

    assert_response :success
    assert_select ".events-empty", count: 1
    assert_select ".event-card", count: 0
  end
end
