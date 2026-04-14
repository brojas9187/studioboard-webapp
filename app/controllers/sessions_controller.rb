class SessionsController < ApplicationController
  def new
    redirect_to after_authentication_path and return if authenticated?
  end

  def create
    user = User.find_by("lower(email) = ?", session_params[:email].to_s.strip.downcase)

    if user&.authenticate(session_params[:password])
      sign_in(user)
      redirect_to after_authentication_path, notice: t("flash.sessions.signed_in", name: user.display_name)
    else
      flash.now[:alert] = t("flash.sessions.invalid_credentials")
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    sign_out
    redirect_to root_path, notice: t("flash.sessions.signed_out")
  end

  private

  def session_params
    params.require(:session).permit(:email, :password)
  end
end
