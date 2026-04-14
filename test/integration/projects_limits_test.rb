require "test_helper"

class ProjectsLimitsTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as(users(:owner))
  end

  test "free plan prevents creating a third project" do
    assert_no_difference("Project.count") do
      post projects_path, params: {
        project: {
          name: "Gamma Rollout",
          description: "This should fail because the plan limit is reached."
        }
      }
    end

    assert_redirected_to billing_path
    follow_redirect!
    assert_match "allows up to 2 projects", response.body
  end
end
