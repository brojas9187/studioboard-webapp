class ProjectsController < ApplicationController
  before_action :require_authentication
  before_action :require_current_organization
  before_action :set_project, only: %i[show edit update destroy]
  before_action :require_project_manager!, only: %i[new create edit update]
  before_action :require_owner!, only: :destroy

  def index
    @projects = current_organization.projects.includes(:creator).order(created_at: :desc)
  end

  def show
    @tasks = persisted_project_tasks
    @form_task = build_form_task
    @member_options = organization_member_options
  end

  def new
    return if enforce_project_limit!

    @project = current_organization.projects.new
  end

  def create
    return if enforce_project_limit!

    @project = current_organization.projects.new(project_params)
    @project.creator = current_user

    if @project.save
      redirect_to project_path(@project), notice: t("flash.projects.created")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @project.update(project_params)
      redirect_to project_path(@project), notice: t("flash.projects.updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    project_name = @project.name
    @project.destroy

    redirect_to projects_path, notice: t("flash.projects.deleted", name: project_name)
  end

  private

  def set_project
    @project = current_organization.projects.find(params[:id])
  end

  def build_form_task
    Task.new(project: @project, assignee: current_user)
  end

  def persisted_project_tasks
    Task.where(project: @project).includes(:assignee, :creator).ordered
  end

  def enforce_project_limit!
    return false if current_organization.can_add_project?

    message = if current_membership.owner?
      t("flash.projects.limit_reached_owner")
    else
      t("flash.projects.limit_reached_member")
    end

    redirect_to(current_membership.owner? ? billing_path : projects_path, alert: message)
    true
  end

  def project_params
    params.require(:project).permit(:name, :description)
  end
end
