class HomeController < ApplicationController
  def index
    return unless authenticated?

    redirect_to after_authentication_path
  end
end
