class TasksController < ApplicationController
  before_action :require_authentication
  before_action :require_current_organization
  before_action :set_project
  before_action :set_task, only: %i[toggle destroy]
  before_action :ensure_task_access!, only: %i[toggle destroy]

  def create
    @task = @project.tasks.new(task_params)
    @task.creator = current_user
    @task.assignee = current_user unless project_management_allowed?
    @task.assignee ||= current_user

    if @task.save
      flash.now[:notice] = t("flash.tasks.created")
      prepare_project_state(form_task: build_form_task)
      respond_to do |format|
        format.html { redirect_to project_path(@project), notice: t("flash.tasks.created") }
        format.turbo_stream { render :refresh }
      end
    else
      prepare_project_state(form_task: @task)
      respond_to do |format|
        format.html { render "projects/show", status: :unprocessable_entity }
        format.turbo_stream { render :refresh, status: :unprocessable_entity }
      end
    end
  end

  def toggle
    @task.toggle_completion!
    flash.now[:notice] = t("flash.tasks.updated")
    prepare_project_state(form_task: build_form_task)

    respond_to do |format|
      format.html { redirect_to project_path(@project), notice: t("flash.tasks.updated") }
      format.turbo_stream { render :refresh }
    end
  end

  def destroy
    @task.destroy
    flash.now[:notice] = t("flash.tasks.deleted")
    prepare_project_state(form_task: build_form_task)

    respond_to do |format|
      format.html { redirect_to project_path(@project), notice: t("flash.tasks.deleted") }
      format.turbo_stream { render :refresh }
    end
  end

  private

  def set_project
    @project = current_organization.projects.find(params[:project_id])
  end

  def set_task
    @task = @project.tasks.find(params[:id])
  end

  def ensure_task_access!
    return if task_management_allowed?(@task)

    redirect_to project_path(@project), alert: t("flash.tasks.forbidden")
  end

  def prepare_project_state(form_task:)
    @project.reload
    @tasks = Task.where(project: @project).includes(:assignee, :creator).ordered
    @member_options = organization_member_options
    @form_task = form_task
  end

  def build_form_task
    Task.new(project: @project, assignee: current_user)
  end

  def task_params
    params.require(:task).permit(:title, :description, :assignee_id)
  end
end
