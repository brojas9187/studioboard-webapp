class BillingController < ApplicationController
  before_action :require_authentication
  before_action :require_current_organization
  before_action :require_owner!

  def show
    flash.now[:notice] = t("flash.billing.checkout_success") if params[:checkout] == "success"
    flash.now[:alert] = t("flash.billing.checkout_cancelled") if params[:checkout] == "cancelled"

    @stripe_configured = %w[STRIPE_SECRET_KEY STRIPE_PRICE_ID STRIPE_WEBHOOK_SECRET].all? { |key| ENV[key].present? }
    @portal_available = current_organization.stripe_customer_id.present?
    @payment_method_types = StripeCheckoutSessionCreator.payment_method_types
  end

  def checkout
    checkout_url = StripeCheckoutSessionCreator.new(
      organization: current_organization,
      user: current_user,
      success_url: billing_url(checkout: "success"),
      cancel_url: billing_url(checkout: "cancelled"),
      locale: stripe_locale
    ).call

    redirect_to checkout_url, allow_other_host: true
  rescue StripeCheckoutSessionCreator::Error => e
    redirect_to billing_path, alert: e.message
  end

  def portal
    portal_url = StripeBillingPortalSessionCreator.new(
      organization: current_organization,
      return_url: billing_url,
      locale: stripe_locale
    ).call

    redirect_to portal_url, allow_other_host: true
  rescue StripeBillingPortalSessionCreator::Error => e
    redirect_to billing_path, alert: e.message
  end

  private

  def stripe_locale
    current_locale.to_s == "es" ? "es-419" : current_locale.to_s
  end
end
