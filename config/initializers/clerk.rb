Clerk.configure do |config|
  config.publishable_key = ENV["CLERK_PUBLISHABLE_KEY"] if ENV["CLERK_PUBLISHABLE_KEY"].present?
  config.secret_key = ENV["CLERK_SECRET_KEY"] if ENV["CLERK_SECRET_KEY"].present?
  config.excluded_routes = [ "/up" ]
end
