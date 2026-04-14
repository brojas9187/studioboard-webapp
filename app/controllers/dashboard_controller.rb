class DashboardController < ApplicationController
  before_action :require_authentication
  before_action :require_current_organization

  def show
    tasks_scope = Task.joins(:project).where(projects: { organization_id: current_organization.id })

    @project_count = current_organization.projects.count
    @member_count = current_organization.memberships.count
    @task_count = tasks_scope.count
    @completed_task_count = tasks_scope.where(completed: true).count
    @recent_projects = current_organization.projects.includes(:creator).order(updated_at: :desc).limit(5)
    @open_tasks = tasks_scope.where(completed: false).includes(:project, :assignee).order(created_at: :desc).limit(6)
  end
end
