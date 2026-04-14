require "test_helper"

class BillingPortalFlowTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as(users(:pro_owner))
  end

  test "owner can open the stripe billing portal" do
    portal_session = Struct.new(:url) do
      def call
        url
      end
    end.new("https://billing.stripe.com/p/session/test_123")

    singleton_class = class << StripeBillingPortalSessionCreator; self; end
    singleton_class.alias_method :__original_new_for_test, :new
    singleton_class.define_method(:new) do |*|
      portal_session
    end

    post portal_billing_path
    assert_redirected_to "https://billing.stripe.com/p/session/test_123"
  ensure
    singleton_class.alias_method :new, :__original_new_for_test
    singleton_class.remove_method :__original_new_for_test
  end
end
