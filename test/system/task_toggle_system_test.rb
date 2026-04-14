require "application_system_test_case"

class TaskToggleSystemTest < ApplicationSystemTestCase
  test "user can toggle a task from pending to done and back to pending" do
    visit new_session_path

    fill_in "session_email", with: users(:member).email
    fill_in "session_password", with: "password123"
    within("form[action='#{session_path}']") do
      click_button I18n.t("app.actions.sign_in")
    end
    assert_current_path dashboard_path, ignore_query: true

    visit project_path(projects(:alpha))

    click_on I18n.t("app.actions.mark_done")
    assert_text I18n.t("app.task_status.done")
    assert_text I18n.t("app.actions.mark_pending")

    click_on I18n.t("app.actions.mark_pending")
    assert_text I18n.t("app.task_status.pending")
    assert_text I18n.t("app.actions.mark_done")
  end
end
