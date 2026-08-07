module Billetto
  class EventsImporter
    Result = Struct.new(:imported, :api_total, :pages, keyword_init: true) do
      def empty?
        api_total.zero?
      end
    end

    def initialize(fetcher: EventsFetcher.new)
      @fetcher = fetcher
    end

    def import_all(params: {})
      imported_count = 0
      pages = 0
      api_total = 0
      result = fetcher.fetch_events(params: params)

      loop do
        pages += 1
        api_total = result[:total]
        imported_count += import_events(result[:events])
        break unless result[:has_more] && result[:next_url]

        result = fetcher.fetch_events_from_url(result[:next_url])
      end

      Result.new(imported: imported_count, api_total: api_total, pages: pages)
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
