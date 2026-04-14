require "test_helper"

class OrganizationTest < ActiveSupport::TestCase
  test "free plan enforces project and member limits" do
    organization = organizations(:studio)

    assert_equal 2, organization.project_limit
    assert_equal 3, organization.member_limit
    assert_not organization.can_add_project?
    assert_not organization.can_add_member?
  end

  test "pro plan removes limits" do
    organization = organizations(:pro_studio)

    assert_nil organization.project_limit
    assert_nil organization.member_limit
    assert organization.can_add_project?
    assert organization.can_add_member?
  end
end
