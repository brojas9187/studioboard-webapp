class RegistrationsController < ApplicationController
  def new
    redirect_to after_authentication_path and return if authenticated?

    @user = User.new
  end

  def create
    @user = User.new(user_params.except(:password, :password_confirmation))
    @user.password = user_params[:password]
    @user.password_confirmation = user_params[:password_confirmation]

    if @user.save
      sign_in(@user)
      redirect_to new_organization_path, notice: t("flash.registrations.created")
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation)
  end
end
