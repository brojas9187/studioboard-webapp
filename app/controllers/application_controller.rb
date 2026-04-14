class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :set_locale
  before_action :resume_session

  helper_method :authenticated?, :current_user, :current_organization, :current_membership,
                :project_management_allowed?, :task_management_allowed?, :current_locale, :available_locales,
                :google_oauth_configured?

  private

  def set_locale
    I18n.locale = requested_locale
    session[:locale] = I18n.locale.to_s
  end

  def requested_locale
    locale = params[:locale].presence || session[:locale].presence || I18n.default_locale
    locale.to_s.in?(I18n.available_locales.map(&:to_s)) ? locale : I18n.default_locale
  end

  def resume_session
    Current.user = User.find_by(id: session[:user_id]) if session[:user_id].present?
    return unless Current.user

    organization = Current.user.organizations.find_by(id: session[:current_organization_id]) ||
                   Current.user.organizations.order(:name).first
    set_current_organization(organization)
  end

  def sign_in(user)
    reset_session
    session[:user_id] = user.id
    Current.user = user
    set_current_organization(user.organizations.order(:name).first)
  end

  def sign_out
    reset_session
    Current.reset
  end

  def set_current_organization(organization)
    Current.organization = organization
    Current.membership = if organization.present? && Current.user.present?
      Current.user.memberships.find_by(organization: organization)
    end
    session[:current_organization_id] = organization&.id
  end

  def current_user
    Current.user
  end

  def authenticated?
    current_user.present?
  end

  def current_locale
    I18n.locale
  end

  def available_locales
    I18n.available_locales
  end

  def google_oauth_configured?
    ENV["GOOGLE_CLIENT_ID"].present? && ENV["GOOGLE_CLIENT_SECRET"].present?
  end

  def current_organization
    Current.organization
  end

  def current_membership
    Current.membership
  end

  def require_authentication
    return if authenticated?

    redirect_to new_session_path, alert: t("flash.authentication.required")
  end

  def require_current_organization
    return if current_organization.present?

    redirect_to new_organization_path, alert: t("flash.organizations.required")
  end

  def require_owner!
    return if current_membership&.owner?

    redirect_to dashboard_path, alert: t("flash.authorization.owner_only")
  end

  def require_project_manager!
    return if project_management_allowed?

    redirect_to projects_path, alert: t("flash.authorization.project_manager_required")
  end

  def project_management_allowed?
    current_membership&.owner? || current_membership&.admin?
  end

  def task_management_allowed?(task)
    return false unless current_membership

    project_management_allowed? || task.assignee_id == current_user.id
  end

  def after_authentication_path
    current_user.memberships.exists? ? dashboard_path : new_organization_path
  end

  def organization_member_options
    current_organization.memberships.includes(:user).order(created_at: :asc)
  end
end
