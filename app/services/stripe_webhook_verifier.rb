require "json"
require "openssl"

class StripeWebhookVerifier
  class Error < StandardError; end

  TOLERANCE_SECONDS = 300

  def initialize(payload:, signature_header:, secret:)
    @payload = payload
    @signature_header = signature_header
    @secret = secret
  end

  def verified_event
    timestamp, signatures = parse_signature_header
    raise Error, "Webhook timestamp is too old." if timestamp < TOLERANCE_SECONDS.seconds.ago.to_i

    signed_payload = "#{timestamp}.#{@payload}"
    expected_signature = OpenSSL::HMAC.hexdigest("SHA256", @secret, signed_payload)
    valid_signature = signatures.any? { |signature| secure_compare(signature, expected_signature) }

    raise Error, "Webhook signature is invalid." unless valid_signature

    JSON.parse(@payload)
  rescue JSON::ParserError
    raise Error, "Webhook payload could not be parsed."
  end

  private

  def parse_signature_header
    raise Error, "Missing Stripe signature header." if @signature_header.blank?

    grouped_parts = @signature_header.split(",").each_with_object(Hash.new { |hash, key| hash[key] = [] }) do |part, hash|
      key, value = part.split("=", 2)
      next if key.blank? || value.blank?

      hash[key] << value
    end

    raw_timestamp = grouped_parts["t"].first
    signatures = grouped_parts["v1"]
    raise Error, "Stripe signature header is malformed." if raw_timestamp.blank? || signatures.empty?

    [raw_timestamp.to_i, signatures]
  end

  def secure_compare(left, right)
    return false if left.bytesize != right.bytesize

    ActiveSupport::SecurityUtils.secure_compare(left, right)
  end
end
