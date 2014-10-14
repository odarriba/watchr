class ApplicationController < ActionController::Base
  # Check if exists any user
  before_action :check_installation
  # Check if the user is logged in
  before_action :authenticate_user!
  # Set a correct locale
  before_filter :set_locale

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  protected

  # Function to check if there is any administrator user.
  # If there isn't one, redirect the user to the installtion
  # form.
  #
  def check_installation
    if (User.where(:level => User::ADMINISTRATOR_USER).count == 0)
      redirect_to start_installation_url()
      return
    end
  end

  # Before action that applies the locale preferred by the user, if
  # logged in.
  #
  def set_locale
    if (user_signed_in? && I18n.available_locales.include?(current_user.lang))
      # If a user is signed in, put the last language used.
      I18n.locale = current_user.lang
    else
      # If there is not user logged in, use the default value
      # defined in config.
      I18n.locale = I18n.default_locale
    end
  end

  # Before action to check the administrator privilege level of 
  # the current user. 
  # This function is used by other controllers in order to allow 
  # privilege-based actions.
  #
  def check_administrator_user
    result = (current_user.is_administrator?)

    if (!result)
      # If it doesn't meet the minimum privilege level, redirect.
      redirect_to root_path()
    end

    return result
  end

  # Before action to check the normal privilege level of 
  # the current user. 
  # This function is used by other controllers in order to allow 
  # privilege-based actions.
  #
  def check_normal_user
    result = ((current_user.is_administrator?) || (current_user.is_normal?))
    
    if (!result)
      # If it doesn't meet the minimum privilege level, redirect.
      redirect_to root_path()
    end

    return result
  end

  # Before action to check the normal privilege level of 
  # the current user. 
  # This function is used by other controllers in order to allow 
  # privilege-based actions.
  #
  def check_guest_user
    # This will return true always, but it is checked just in case.
    result = ((current_user.is_administrator?) || (current_user.is_normal?) || (current_user.is_guest?))

    if (!result)
      # If it doesn't meet the minimum privilege level, redirect.
      redirect_to root_path()
    end

    return result
  end

  private

  # Overwriting the sign_out redirect path method to redirect
  # the user to the login form instead of the root url.
  #
  def after_sign_out_path_for(resource_or_scope)
    return session_path(resource_or_scope)
  end
end
