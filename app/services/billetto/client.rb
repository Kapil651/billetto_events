require "net/http"
require "json"

module Billetto
  class Client
    BASE_HOST = "billetto.dk"
    API_VERSION = "2026-06-16"
    OPEN_TIMEOUT = 10
    READ_TIMEOUT = 30

    def get(path, params = {})
      uri = build_uri(path, params)
      request = build_request(uri)
      execute(uri, request)
    end

    def get_url(url)
      uri = URI.parse(url)
      request = build_request(uri)
      execute(uri, request)
    end

    private

    def build_uri(path, params)
      uri = URI::HTTPS.build(host: BASE_HOST, path: path)
      uri.query = URI.encode_www_form(params.compact) if params.present?
      uri
    end

    def build_request(uri)
      request = Net::HTTP::Get.new(uri)
      request["Accept"] = "application/json"
      request["Api-Keypair"] = api_keypair
      request["Billetto-Version"] = API_VERSION
      request
    end

    def execute(uri, request)
      response = http_client(uri).request(request)
      handle_response(response)
    rescue Timeout::Error, Errno::ECONNREFUSED, SocketError, OpenSSL::SSL::SSLError => e
      raise Billetto::RequestError, "Failed to connect to Billetto API: #{e.message}"
    end

    def http_client(uri)
      Net::HTTP.start(
        uri.host,
        uri.port,
        use_ssl: true,
        open_timeout: OPEN_TIMEOUT,
        read_timeout: READ_TIMEOUT
      )
    end

    def handle_response(response)
      body = parse_json(response.body)

      case response
      when Net::HTTPSuccess
        body
      when Net::HTTPUnauthorized
        raise Billetto::RequestError.new("Invalid Billetto API credentials", status: response.code.to_i, body: body)
      when Net::HTTPTooManyRequests
        raise Billetto::RequestError.new("Billetto API rate limit exceeded", status: response.code.to_i, body: body)
      else
        message = extract_error_message(body) || "Billetto API request failed with status #{response.code}"
        raise Billetto::RequestError.new(message, status: response.code.to_i, body: body)
      end
    end

    def parse_json(raw_body)
      return {} if raw_body.blank?

      JSON.parse(raw_body)
    rescue JSON::ParserError => e
      raise Billetto::ResponseError, "Invalid JSON response from Billetto API: #{e.message}"
    end

    def extract_error_message(body)
      return unless body.is_a?(Hash)

      body["message"] || body["error"]
    end

    def api_keypair
      key_id = ENV["BILLETTO_ACCESS_KEY_ID"]
      secret = ENV["BILLETTO_ACCESS_KEY_SECRET"]

      if key_id.blank? || secret.blank?
        raise Billetto::ConfigurationError, "BILLETTO_ACCESS_KEY_ID and BILLETTO_ACCESS_KEY_SECRET must be configured"
      end

      "#{key_id}:#{secret}"
    end
  end
end
