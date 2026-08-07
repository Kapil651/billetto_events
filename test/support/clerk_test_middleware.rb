class ClerkTestMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    request = Rack::Request.new(env)
    user_id = request.cookies["test_user_id"].presence || request.params["test_user_id"].presence

    env["clerk"] = Clerk::Proxy.new(session_claims: { "sub" => user_id }) if user_id.present?

    @app.call(env)
  end
end
