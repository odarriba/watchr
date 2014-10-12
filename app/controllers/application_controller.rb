class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  private

  # Overwriting the sign_out redirect path method to redirect
  # the user to the login form instead of the root url.
  #
  def after_sign_out_path_for(resource_or_scope)
    return session_path(resource_or_scope)
  end
end
