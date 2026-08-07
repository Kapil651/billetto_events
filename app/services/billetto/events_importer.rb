module Billetto
  class EventsImporter
    def initialize(fetcher: EventsFetcher.new)
      @fetcher = fetcher
    end

    def import_all(params: {})
      imported_count = 0
      result = fetcher.fetch_events(params: params)

      loop do
        imported_count += import_events(result[:events])
        break unless result[:has_more] && result[:next_url]

        result = fetcher.fetch_events_from_url(result[:next_url])
      end

      imported_count
    end

    def import_event(data)
      Event.upsert_from_billetto!(data)
    end

    private

    attr_reader :fetcher

    def import_events(events)
      Event.transaction do
        events.sum { |data| import_event(data) ? 1 : 0 }
      end
    end
  end
end
