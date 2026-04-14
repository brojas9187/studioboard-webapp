class LocalesController < ApplicationController
  def update
    session[:locale] = requested_locale.to_s

    redirect_to return_path, notice: t("flash.locale_switched", language: helpers.locale_name(requested_locale))
  end

  private

  def return_path
    candidate = params[:return_to].to_s
    return candidate if candidate.start_with?("/")

    root_path
  end
end
