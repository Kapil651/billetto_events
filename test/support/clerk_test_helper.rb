module ClerkTestHelper
  def sign_in_as(user_id)
    if respond_to?(:request) && request
      request.env["clerk"] = clerk_proxy_for(user_id)
    else
      cookies[:test_user_id] = user_id
    end
  end

  def sign_out
    if respond_to?(:request) && request
      request.env["clerk"] = Clerk::Proxy.new
    else
      cookies.delete(:test_user_id)
    end
  end

  def clerk_proxy_for(user_id)
    Clerk::Proxy.new(session_claims: { "sub" => user_id })
  end

  def create_event!(overrides = {})
    defaults = {
      billetto_id: "evt_#{SecureRandom.hex(4)}",
      name: "Sample Event",
      raw_payload: {
        "id" => "evt_sample",
        "object" => "event",
        "name" => "Sample Event",
        "starts_at" => "2026-09-15T19:30:00.000Z"
      }
    }

    attrs = defaults.merge(overrides)
    attrs[:raw_payload] = defaults[:raw_payload].merge(attrs[:raw_payload]) if attrs[:raw_payload].is_a?(Hash)

    Event.create!(attrs)
  end
end
