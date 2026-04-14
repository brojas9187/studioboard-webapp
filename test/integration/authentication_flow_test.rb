require "test_helper"

class AuthenticationFlowTest < ActionDispatch::IntegrationTest
  test "user can sign up and continue to organization setup" do
    assert_difference("User.count", 1) do
      post registration_path, params: {
        user: {
          name: "Jordan New",
          email: "jordan@example.com",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end

    assert_redirected_to new_organization_path

    follow_redirect!
    assert_response :success
    assert_select "h1", text: "Create your first workspace"
  end

  test "user can sign in and sign out" do
    sign_in_as(users(:owner))
    assert_redirected_to dashboard_path

    delete session_path
    assert_redirected_to root_path
  end
end
