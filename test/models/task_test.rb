require "test_helper"

class TaskTest < ActiveSupport::TestCase
  test "member can manage their own task but not someone else's" do
    own_task = tasks(:design_task)
    another_task = tasks(:review_task)
    membership = memberships(:member_membership)

    assert own_task.manageable_by?(membership)
    assert_not another_task.manageable_by?(membership)
  end

  test "admins can manage every task in the organization" do
    membership = memberships(:admin_membership)

    assert tasks(:design_task).manageable_by?(membership)
    assert tasks(:review_task).manageable_by?(membership)
  end
end
