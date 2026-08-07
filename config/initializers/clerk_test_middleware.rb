if Rails.env.test?
  require Rails.root.join("test/support/clerk_test_middleware")

  Rails.application.config.middleware.insert_after Clerk::Rack::Middleware, ClerkTestMiddleware
end
