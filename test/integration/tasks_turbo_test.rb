require "test_helper"

class TasksTurboTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as(users(:member))
  end

  test "member creates a task through turbo and it stays assigned to them" do
    assert_difference("Task.count", 1) do
      post project_tasks_path(projects(:alpha)),
           params: {
             task: {
               title: "Ship QA checklist",
               description: "Draft the release QA list.",
               assignee_id: users(:admin).id
             }
           },
           headers: turbo_stream_headers
    end

    assert_response :success
    assert_equal Mime[:turbo_stream].to_s, response.media_type

    task = Task.order(:created_at).last
    assert_equal users(:member), task.assignee
    assert_includes response.body, "<turbo-stream"
    assert_includes response.body, "Ship QA checklist"
  end

  test "member toggles their task through turbo and sees updated state" do
    task = tasks(:design_task)

    patch toggle_project_task_path(projects(:alpha), task), headers: turbo_stream_headers

    assert_response :success
    assert_equal Mime[:turbo_stream].to_s, response.media_type

    task.reload
    assert task.completed?
    assert_not_nil task.completed_at
    assert_includes response.body, I18n.t("app.task_status.done")
    assert_includes response.body, I18n.t("tasks.panel.counts.done", count: 2)
    assert_includes response.body, I18n.t("tasks.panel.counts.open", count: 0)

    patch toggle_project_task_path(projects(:alpha), task), headers: turbo_stream_headers

    assert_response :success
    assert_equal Mime[:turbo_stream].to_s, response.media_type

    task.reload
    assert_not task.completed?
    assert_nil task.completed_at
    assert_includes response.body, I18n.t("app.task_status.pending")
    assert_includes response.body, I18n.t("tasks.panel.counts.done", count: 1)
    assert_includes response.body, I18n.t("tasks.panel.counts.open", count: 1)
  end

  test "member toggles their task through html and sees updated state" do
    task = tasks(:design_task)

    patch toggle_project_task_path(projects(:alpha), task)
    assert_redirected_to project_path(projects(:alpha))

    task.reload
    assert task.completed?

    patch toggle_project_task_path(projects(:alpha), task)
    assert_redirected_to project_path(projects(:alpha))

    task.reload
    assert_not task.completed?
    assert_nil task.completed_at
  end
end
