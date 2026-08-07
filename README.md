# Tacnique Kapil

Rails application that imports events from the Billetto API, displays them in a simple listing page, and lets authenticated users vote on events. Votes are recorded with Rails Event Store (RES) for traceability.

## Setup

### Prerequisites

- Ruby 3.1.0 (see `.ruby-version`)
- PostgreSQL
- Bundler

### 1. Install dependencies

```bash
bundle install
```

### 2. Configure environment variables

Copy and edit `config/application.yml` with your credentials:

```yaml
development:
  BILLETTO_ACCESS_KEY_ID: your_billetto_key_id
  BILLETTO_ACCESS_KEY_SECRET: your_billetto_secret
  CLERK_PUBLISHABLE_KEY: pk_test_...
  CLERK_SECRET_KEY: sk_test_...
  CLERK_SIGN_IN_URL: http://localhost:3000/sign-in
  CLERK_SIGN_UP_URL: http://localhost:3000/sign-up
  CLERK_SIGN_OUT_URL: http://localhost:3000/
```

- **Billetto:** API keys from your [Billetto](https://billetto.dk) organiser account.
- **Clerk:** Publishable and secret keys from the [Clerk Dashboard](https://dashboard.clerk.com). Add `http://localhost:3000/*` to allowed redirect URLs.

Values in `config/application.yml` are loaded into `ENV` at boot via `config/initializers/application_config.rb`.

### 3. Prepare the database

```bash
bin/rails db:create db:migrate
```

Development uses `tacnique-dev`; test uses `tacnique-test` (see `config/database.yml`). Adjust PostgreSQL username/password if needed.

### 4. Import events (optional)

In a Rails console:

```ruby
Billetto::EventsImporter.new.import_all
```

### 5. Run the app

```bash
bin/rails server
```

Open [http://localhost:3000](http://localhost:3000).

### 6. Running tests

Prepare the test database once (or after migrations change):

```bash
bin/rails db:create db:migrate RAILS_ENV=test
```

#### Run all tests (recommended for CI / bots)

```bash
bundle install
bin/rails db:prepare RAILS_ENV=test
bin/rails test && bin/rails test:system
```

#### Unit and integration tests (Minitest)

```bash
bin/rails test
```

Run a specific file or test:

```bash
bin/rails test test/models/event_test.rb
bin/rails test test/integration/event_store_voting_test.rb
bin/rails test test/models/event_test.rb:77
```

Run tests by area:

```bash
bin/rails test test/models/              # model validations
bin/rails test test/integration/         # auth + event store flows
bin/rails test test/controllers/         # controller tests
bin/rails test test/services/            # Billetto + voting services
bin/rails test test/projectors/          # RES projectors
```

#### Browser / system tests

Requires Google Chrome (headless). Used for sign-in/sign-up/sign-out pages and voting in the browser.

```bash
bin/rails test:system
```

Run a specific system test file:

```bash
bin/rails test:system test/system/authentication_system_test.rb
bin/rails test:system test/system/voting_system_test.rb
```

#### Notes for automated runners

- Tests use Minitest (not RSpec).
- System tests may take longer (~1 minute); unit/integration tests usually finish in a few seconds.
- Clerk auth in tests is stubbed via `test/support/clerk_test_middleware.rb` (no live Clerk API calls required for most tests).
- Exit code is non-zero if any test fails; use `bin/rails test && bin/rails test:system` in CI scripts.

---

## Troubleshooting

### `Invalid Billetto API credentials (Billetto::RequestError)`

Billetto returned **HTTP 401**. The app is sending credentials, but Billetto rejected them.

1. Log in to your [Billetto organiser account](https://billetto.dk).
2. Go to **Menu → Integrate → Developers**.
3. Create a **new API key pair** (or confirm the existing one is active).
4. Update `config/application.yml`:
   ```yaml
   development:
     BILLETTO_ACCESS_KEY_ID: your_key_id
     BILLETTO_ACCESS_KEY_SECRET: your_key_secret
   ```
5. Restart the Rails server (env vars load at boot).
6. Verify:
   ```bash
   bin/rails billetto:verify_credentials
   ```

Common causes: revoked/regenerated keys, copy-paste errors, or keys from a different Billetto account.

### `import_all` returns 0 records

If credentials work but nothing imports, the Billetto API is returning an empty list:

```json
{ "data": [], "total": 0, "has_more": false }
```

This means the **organiser account linked to your API keys has no events yet**. The importer is working; there is simply nothing to fetch.

1. Confirm what Billetto returns:
   ```bash
   bin/rails billetto:verify_credentials
   bin/rails billetto:import_events
   ```
2. Create at least one event in your [Billetto organiser dashboard](https://billetto.dk).
3. Re-run import:
   ```ruby
   Billetto::EventsImporter.new.import_all
   # => #<struct imported=1, api_total=1, pages=1>
   ```

In Rails console, check the API response directly:

```ruby
Billetto::EventsFetcher.new.fetch_events
# => { events: [], has_more: false, total: 0, ... }
```

---

## Approach & Design

### Event ingestion (Billetto)

Events are fetched from the Billetto organiser API using a small service layer under `Billetto::`:

- `Client` — HTTP client with API key authentication
- `EventsFetcher` — paginated list/single-event fetching
- `EventValidator` — validates API response shape before persistence
- `EventsImporter` — upserts validated events into PostgreSQL

Each event is stored with core fields (`name`, `state`, `kind`, etc.) plus the full API payload in `raw_payload` (jsonb). This keeps the schema stable while preserving extra Billetto fields (dates, images, descriptions) for display.

### Event listing

The home page (`EventsController#index`) lists events ordered by `starts_at` from `raw_payload`, with cards showing title, date, image, description, and vote totals.

Display helpers (`title`, `starts_at`, `image_url`, `brief_description`) read from `raw_payload` so the UI stays aligned with the source API.

### Authentication (Clerk)

Authentication is handled by [Clerk](https://clerk.com):

- **Backend:** `clerk-sdk-ruby` with `Clerk::Authenticatable` and Rack middleware for session verification
- **Frontend:** Clerk JS SDK (CDN) with embedded Sign In / Sign Up components on `/sign-in` and `/sign-up`
- **Logout:** Client-side `Clerk.signOut()` on `/sign-out`

Voting requires a signed-in user (`before_action :require_clerk_session!` on `EventVotesController`).

### Voting (Rails Event Store)

Voting uses an event-sourced pattern:

| Layer | Responsibility |
|-------|----------------|
| Domain events | `Voting::EventUpvoted`, `Voting::EventDownvoted` — stored in RES with `event_id` and `user_id` |
| Service | `Voting::CastVote` — publishes events to stream `Event$<id>` |
| Projector | `Voting::EventVoteProjector` — updates read model on each event |
| Read model | `event_votes` table + `upvotes_count` / `downvotes_count` on `events` |

RES is the source of truth for vote history and user traceability. The read model provides fast counts for the listing page. One vote per user per event is enforced; switching from like to dislike publishes a new event and adjusts counters.

### Assumptions

1. **Single event source** — Billetto is the only upstream provider; events are keyed by `billetto_id`.
2. **Clerk user IDs** — Votes are tied to Clerk `user_id` (string); no local User model is maintained.
3. **Optional event fields** — Billetto `name`, `starts_at`, and `image_url` may be absent; the UI handles missing data gracefully.
4. **Synchronous projection** — Vote counters are updated inline when RES events are published (no background job queue).
5. **Development credentials** — `config/application.yml` holds secrets for local dev; production should use a secure secret manager or encrypted credentials.
