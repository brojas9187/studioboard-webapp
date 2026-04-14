class StripeWebhooksController < ActionController::Base
  skip_forgery_protection

  def create
    secret = ENV["STRIPE_WEBHOOK_SECRET"]
    return head :service_unavailable if secret.blank?

    event = StripeWebhookVerifier.new(
      payload: request.raw_post,
      signature_header: request.headers["Stripe-Signature"],
      secret: secret
    ).verified_event

    process_event(event)
    head :ok
  rescue StripeWebhookVerifier::Error => e
    Rails.logger.warn("Stripe webhook rejected: #{e.message}")
    head :bad_request
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error("Stripe webhook processing failed: #{e.message}")
    head :unprocessable_entity
  end

  private

  def process_event(event)
    case event["type"]
    when "checkout.session.completed"
      handle_checkout_completed(event.dig("data", "object") || {})
    when "customer.subscription.deleted"
      handle_subscription_deleted(event.dig("data", "object") || {})
    end
  end

  def handle_checkout_completed(payload)
    organization_id = payload.dig("metadata", "organization_id") || payload["client_reference_id"]
    return if organization_id.blank?

    organization = Organization.find_by(id: organization_id)
    return if organization.blank?

    organization.upgrade_to_pro!(
      customer_id: payload["customer"],
      subscription_id: payload["subscription"]
    )
  end

  def handle_subscription_deleted(payload)
    organization = Organization.find_by(stripe_subscription_id: payload["id"])
    return if organization.blank?

    organization.update!(plan: "free")
  end
end
