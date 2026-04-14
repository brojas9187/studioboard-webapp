require "test_helper"

class GoogleOauthFlowTest < ActionDispatch::IntegrationTest
  setup do
    @previous_auth = Rails.application.env_config["omniauth.auth"]
  end

  teardown do
    Rails.application.env_config["omniauth.auth"] = @previous_auth
  end

  test "google callback creates a user and starts a session" do
    Rails.application.env_config["omniauth.auth"] = OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: "google-123",
      info: {
        email: "google-user@example.com",
        name: "Google User",
        image: "https://example.com/avatar.png"
      }
    )

    assert_difference("User.count", 1) do
      get "/auth/google_oauth2/callback"
    end

    assert_redirected_to new_organization_path

    user = User.find_by!(email: "google-user@example.com")
    assert_equal "google_oauth2", user.oauth_provider
    assert_equal "google-123", user.oauth_uid
  end

  test "google callback links an existing account by email" do
    user = users(:owner)

    Rails.application.env_config["omniauth.auth"] = OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: "google-owner",
      info: {
        email: user.email,
        name: user.name
      }
    )

    assert_no_difference("User.count") do
      get "/auth/google_oauth2/callback"
    end

    assert_redirected_to dashboard_path
    user.reload
    assert_equal "google_oauth2", user.oauth_provider
    assert_equal "google-owner", user.oauth_uid
  end
end
