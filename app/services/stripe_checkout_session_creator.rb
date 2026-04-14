require "json"
require "net/http"
require "uri"

class StripeCheckoutSessionCreator
  class Error < StandardError; end

  CHECKOUT_ENDPOINT = URI("https://api.stripe.com/v1/checkout/sessions")

  def initialize(organization:, user:, success_url:, cancel_url:, locale: nil)
    @organization = organization
    @user = user
    @success_url = success_url
    @cancel_url = cancel_url
    @locale = locale
  end

  def call
    ensure_configuration!

    request = Net::HTTP::Post.new(CHECKOUT_ENDPOINT)
    request["Authorization"] = "Bearer #{ENV.fetch("STRIPE_SECRET_KEY")}"
    request["Content-Type"] = "application/x-www-form-urlencoded"
    request.body = URI.encode_www_form(payload)

    response = Net::HTTP.start(CHECKOUT_ENDPOINT.hostname, CHECKOUT_ENDPOINT.port, use_ssl: true) do |http|
      http.request(request)
    end

    response_body = JSON.parse(response.body)
    unless response.is_a?(Net::HTTPSuccess)
      raise Error, response_body.dig("error", "message") || I18n.t("services.stripe.checkout_creation_failed")
    end

    response_body.fetch("url")
  rescue JSON::ParserError
    raise Error, I18n.t("services.stripe.unreadable_response")
  end

  private

  def self.payment_method_types
    ENV.fetch("STRIPE_PAYMENT_METHOD_TYPES", "card")
       .split(",")
       .map { |value| value.strip.downcase }
       .reject(&:blank?)
       .presence || ["card"]
  end

  def payment_method_types
    self.class.payment_method_types
  end

  public_class_method :payment_method_types

  def ensure_configuration!
    missing = %w[STRIPE_SECRET_KEY STRIPE_PRICE_ID].select { |key| ENV[key].blank? }
    return if missing.empty?

    raise Error, I18n.t("services.stripe.missing_configuration", keys: missing.join(", "))
  end

  def payload
    attributes = {
      "mode" => "subscription",
      "success_url" => @success_url,
      "cancel_url" => @cancel_url,
      "client_reference_id" => @organization.id,
      "metadata[organization_id]" => @organization.id,
      "metadata[user_id]" => @user.id,
      "line_items[0][price]" => ENV.fetch("STRIPE_PRICE_ID"),
      "line_items[0][quantity]" => 1,
      "payment_method_collection" => "always"
    }

    if @organization.stripe_customer_id.present?
      attributes["customer"] = @organization.stripe_customer_id
    else
      attributes["customer_email"] = @user.email
    end

    payment_method_types.each_with_index do |payment_method_type, index|
      attributes["payment_method_types[#{index}]"] = payment_method_type
    end

    attributes["locale"] = @locale if @locale.present?

    attributes
  end
end
