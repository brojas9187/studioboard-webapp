class OauthSessionsController < ApplicationController
  def create
    user = GoogleOauthAuthenticator.new(auth_hash: request.env["omniauth.auth"]).call
    sign_in(user)

    redirect_to after_authentication_path, notice: t("flash.oauth.google_signed_in", name: user.display_name)
  rescue GoogleOauthAuthenticator::Error, ActiveRecord::RecordInvalid => e
    redirect_to new_session_path, alert: e.message.presence || t("flash.oauth.google_failed")
  end

  def failure
    message = if params[:message].present?
      t("flash.oauth.google_failed_with_reason", reason: params[:message].to_s.tr("_", " "))
    else
      t("flash.oauth.google_failed")
    end

    redirect_to new_session_path, alert: message
  end
end
