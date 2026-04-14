require "test_helper"

class MembershipLimitsTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as(users(:owner))
  end

  test "free plan prevents adding a fourth member" do
    assert_no_difference("Membership.count") do
      post memberships_path, params: {
        membership: {
          email: users(:extra).email,
          role: "member"
        }
      }
    end

    assert_redirected_to memberships_path
    follow_redirect!
    assert_match "member limit", response.body
  end
end
