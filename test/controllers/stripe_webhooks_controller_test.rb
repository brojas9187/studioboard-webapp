require "test_helper"
require "openssl"

class StripeWebhooksControllerTest < ActionDispatch::IntegrationTest
  test "checkout session webhook upgrades the organization to pro" do
    organization = organizations(:studio)
    payload = {
      type: "checkout.session.completed",
      data: {
        object: {
          client_reference_id: organization.id.to_s,
          customer: "cus_123",
          subscription: "sub_123",
          metadata: {
            organization_id: organization.id.to_s
          }
        }
      }
    }.to_json

    secret = "whsec_test"
    timestamp = Time.current.to_i
    signature = OpenSSL::HMAC.hexdigest("SHA256", secret, "#{timestamp}.#{payload}")

    with_env("STRIPE_WEBHOOK_SECRET" => secret) do
      post stripe_webhook_path,
           params: payload,
           headers: {
             "CONTENT_TYPE" => "application/json",
             "Stripe-Signature" => "t=#{timestamp},v1=#{signature}"
           }
    end

    assert_response :success
    organization.reload
    assert_equal "pro", organization.plan
    assert_equal "cus_123", organization.stripe_customer_id
    assert_equal "sub_123", organization.stripe_subscription_id
  end
end
