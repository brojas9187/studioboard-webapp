require "test_helper"

class LocaleSwitchingTest < ActionDispatch::IntegrationTest
  test "user can switch the interface to spanish" do
    patch switch_locale_path(locale: :es), params: { return_to: root_path }

    assert_redirected_to root_path

    follow_redirect!
    assert_response :success
    assert_match "Gestiona proyectos, roles y cobros", response.body

    get new_session_path
    assert_match "Iniciar sesión", response.body
  end
end
