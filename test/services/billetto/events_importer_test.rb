require "test_helper"

class Billetto::EventsImporterTest < ActiveSupport::TestCase
  class FakeFetcher
    attr_reader :calls

    def initialize(responses)
      @responses = responses
      @calls = []
    end

    def fetch_events(params: {})
      @calls << [ :fetch_events, params ]
      shift_response!
    end

    def fetch_events_from_url(url)
      @calls << [ :fetch_events_from_url, url ]
      shift_response!
    end

    private

    def shift_response!
      response = @responses.shift
      raise "Unexpected fetcher call" if response.nil?

      response
    end
  end

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

  test "import_all fetches and persists events across pages" do
    fetcher = FakeFetcher.new(
      [
        {
          events: [ valid_billetto_event("id" => "evt_1") ],
          has_more: true,
          next_url: "https://billetto.dk/api/v3/organiser/events?page=2",
          total: 2
        },
        {
          events: [ valid_billetto_event("id" => "evt_2", "name" => "Winter Show") ],
          has_more: false,
          next_url: nil,
          total: 2
        }
      ]
    )

    importer = Billetto::EventsImporter.new(fetcher: fetcher)

    assert_equal 2, importer.import_all.imported
    assert_equal 2, Event.count
    assert_equal "Winter Show", Event.find_by(billetto_id: "evt_2").name
    assert_equal [ [ :fetch_events, {} ], [ :fetch_events_from_url, "https://billetto.dk/api/v3/organiser/events?page=2" ] ], fetcher.calls
  end

  test "import_all is idempotent for repeated imports" do
    first_response = {
      events: [ valid_billetto_event("name" => "First Import") ],
      has_more: false,
      next_url: nil,
      total: 1
    }
    second_response = {
      events: [ valid_billetto_event("name" => "Second Import") ],
      has_more: false,
      next_url: nil,
      total: 1
    }

    importer = Billetto::EventsImporter.new(fetcher: FakeFetcher.new([ first_response, second_response ]))

    importer.import_all
    importer.import_all

    assert_equal 1, Event.count
    assert_equal "Second Import", Event.first.name
  end

  test "import_all reports api total when no events exist" do
    fetcher = FakeFetcher.new(
      [
        {
          events: [],
          has_more: false,
          next_url: nil,
          total: 0
        }
      ]
    )

    result = Billetto::EventsImporter.new(fetcher: fetcher).import_all

    assert result.empty?
    assert_equal 0, result.imported
    assert_equal 0, result.api_total
  end

  test "import_event persists a single event" do
    importer = Billetto::EventsImporter.new(fetcher: FakeFetcher.new([]))

    event = importer.import_event(valid_billetto_event)

    assert event.persisted?
    assert_equal "evt_123", event.billetto_id
  end

  test "import_events rolls back the batch when one event is invalid" do
    fetcher = FakeFetcher.new(
      [
        {
          events: [
            valid_billetto_event("id" => "evt_valid"),
            { "object" => "event" }
          ],
          has_more: false,
          next_url: nil,
          total: 2
        }
      ]
    )

    importer = Billetto::EventsImporter.new(fetcher: fetcher)

    assert_raises(Billetto::ValidationError) do
      importer.import_all
    end

    assert_equal 0, Event.count
  end
end
