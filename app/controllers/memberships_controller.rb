class MembershipsController < ApplicationController
  before_action :require_authentication
  before_action :require_current_organization
  before_action :require_owner!, except: :index
  before_action :set_membership, only: %i[update destroy]

  def index
    load_memberships
  end

  def create
    email = membership_params[:email].to_s.strip.downcase
    role = membership_params[:role].presence || "member"

    unless current_organization.can_add_member?
      redirect_to memberships_path, alert: t("flash.memberships.member_limit_reached")
      return
    end

    if email.blank?
      redirect_to memberships_path, alert: t("flash.memberships.email_required")
      return
    end

    user = User.find_by("lower(email) = ?", email)
    unless user
      redirect_to memberships_path, alert: t("flash.memberships.user_missing")
      return
    end

    membership = current_organization.memberships.new(user: user, role: role)

    if membership.save
      redirect_to memberships_path, notice: t(
        "flash.memberships.created",
        user: user.display_name,
        organization: current_organization.name,
        role: helpers.translated_role_name(role)
      )
    else
      redirect_to memberships_path, alert: membership.errors.full_messages.to_sentence
    end
  end

  def update
    if @membership.owner?
      redirect_to memberships_path, alert: t("flash.memberships.owner_role_locked")
    elsif @membership.update(role: membership_params[:role])
      redirect_to memberships_path, notice: t(
        "flash.memberships.updated",
        user: @membership.user.display_name,
        role: helpers.translated_role_name(@membership.role)
      )
    else
      redirect_to memberships_path, alert: @membership.errors.full_messages.to_sentence
    end
  end

  def destroy
    if @membership.owner?
      redirect_to memberships_path, alert: t("flash.memberships.owner_membership_locked")
    elsif @membership.user_id == current_user.id
      redirect_to memberships_path, alert: t("flash.memberships.cannot_remove_self")
    else
      removed_name = @membership.user.display_name
      @membership.destroy
      redirect_to memberships_path, notice: t("flash.memberships.removed", user: removed_name)
    end
  end

  private

  def load_memberships
    @memberships = current_organization.memberships.alphabetical.includes(:user)
  end

  def set_membership
    @membership = current_organization.memberships.includes(:user).find(params[:id])
  end

  def membership_params
    params.require(:membership).permit(:email, :role)
  end
end
