module ClerkHelper
  def clerk_publishable_key
    ENV["CLERK_PUBLISHABLE_KEY"].presence
  end

  def clerk_frontend_api_host
    return if clerk_publishable_key.blank?
    return unless Clerk::Utils.valid_publishable_key?(clerk_publishable_key)

    Clerk::Utils.decode_publishable_key(clerk_publishable_key).chop
  end

  def clerk_configured?
    clerk_publishable_key.present? &&
      ENV["CLERK_SECRET_KEY"].present? &&
      Clerk::Utils.valid_publishable_key?(clerk_publishable_key)
  rescue ArgumentError
    false
  end
end
