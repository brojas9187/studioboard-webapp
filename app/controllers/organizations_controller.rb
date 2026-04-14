class OrganizationsController < ApplicationController
  before_action :require_authentication
  before_action :set_owned_organization, only: %i[edit update]

  def new
    @organization = Organization.new
  end

  def create
    @organization = Organization.new(organization_params)

    ActiveRecord::Base.transaction do
      @organization.save!
      @organization.memberships.create!(user: current_user, role: :owner)
    end

    set_current_organization(@organization)
    redirect_to dashboard_path, notice: t("flash.organizations.created")
  rescue ActiveRecord::RecordInvalid
    render :new, status: :unprocessable_entity
  end

  def edit
  end

  def update
    if @organization.update(organization_params)
      redirect_to dashboard_path, notice: t("flash.organizations.updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def switch
    membership = current_user.memberships.includes(:organization).find_by!(organization_id: params[:id])
    set_current_organization(membership.organization)

    redirect_back fallback_location: dashboard_path, notice: t("flash.organizations.switched", name: membership.organization.name)
  end

  private

  def set_owned_organization
    membership = current_user.memberships.includes(:organization).find_by!(organization_id: params[:id], role: "owner")
    @organization = membership.organization
  end

  def organization_params
    params.require(:organization).permit(:name)
  end
end
