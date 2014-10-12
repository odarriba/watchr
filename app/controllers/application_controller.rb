class ApplicationController < ActionController::Base
  # Check if exists any user
  before_action :check_installation
  # Check if the user is logged in
  before_action :authenticate_user!

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  protected

  # Function to check if there is any administrator user.
  # If there isn't one, redirect the user to the installtion
  # form.
  #
  def check_installation
    if (User.where(:level => User::ADMINISTRATOR).count == 0)
      redirect_to start_installation_url()
      return
    end
  end

  private

  # Overwriting the sign_out redirect path method to redirect
  # the user to the login form instead of the root url.
  #
  def after_sign_out_path_for(resource_or_scope)
    return session_path(resource_or_scope)
  end
end
