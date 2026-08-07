namespace :billetto do
  desc "Verify Billetto API credentials by fetching one event"
  task verify_credentials: :environment do
    key_id = ENV["BILLETTO_ACCESS_KEY_ID"]
    secret = ENV["BILLETTO_ACCESS_KEY_SECRET"]

    if key_id.blank? || secret.blank?
      abort "Missing credentials. Set BILLETTO_ACCESS_KEY_ID and BILLETTO_ACCESS_KEY_SECRET in config/application.yml"
    end

    print "Checking Billetto credentials for key #{key_id.slice(0, 8)}... "
    $stdout.flush
    result = Billetto::EventsFetcher.new.fetch_events(params: { limit: 1 })
    puts "OK (#{result[:events].size} event(s) returned, total: #{result[:total]})"
  rescue Billetto::RequestError => e
    puts "FAILED"
    $stderr.puts e.message
    $stderr.puts "API response: #{e.body.inspect}" if e.body.present?
    exit 1
  end

  desc "Import events from Billetto into the local database"
  task import_events: :environment do
    result = Billetto::EventsImporter.new.import_all

    puts "Imported #{result.imported} event(s) from Billetto (API total: #{result.api_total}, pages: #{result.pages})"

    if result.empty?
      puts <<~MSG

        No events were returned by the Billetto API for this organiser account.
        Create events in your Billetto dashboard first: https://billetto.dk
        Then run: bin/rails billetto:import_events
      MSG
    end
  end
end
