require "json"
require "net/http"
require "uri"

class StripeBillingPortalSessionCreator
  class Error < StandardError; end

  PORTAL_ENDPOINT = URI("https://api.stripe.com/v1/billing_portal/sessions")

  def initialize(organization:, return_url:, locale: nil)
    @organization = organization
    @return_url = return_url
    @locale = locale
  end

  def call
    ensure_configuration!
    raise Error, I18n.t("services.stripe.customer_portal_missing_customer") if @organization.stripe_customer_id.blank?

    request = Net::HTTP::Post.new(PORTAL_ENDPOINT)
    request["Authorization"] = "Bearer #{ENV.fetch("STRIPE_SECRET_KEY")}"
    request["Content-Type"] = "application/x-www-form-urlencoded"
    request.body = URI.encode_www_form(payload)

    response = Net::HTTP.start(PORTAL_ENDPOINT.hostname, PORTAL_ENDPOINT.port, use_ssl: true) do |http|
      http.request(request)
    end

    response_body = JSON.parse(response.body)
    unless response.is_a?(Net::HTTPSuccess)
      raise Error, response_body.dig("error", "message") || I18n.t("services.stripe.portal_creation_failed")
    end

    response_body.fetch("url")
  rescue JSON::ParserError
    raise Error, I18n.t("services.stripe.unreadable_response")
  end

  private

  def ensure_configuration!
    raise Error, I18n.t("services.stripe.secret_key_missing") if ENV["STRIPE_SECRET_KEY"].blank?
  end

  def payload
    attributes = {
      "customer" => @organization.stripe_customer_id,
      "return_url" => @return_url
    }
    attributes["locale"] = @locale if @locale.present?
    attributes
  end
end
