# Application is the main controller.
#
# Others controllers in the app inherits from this, so things like
# per-privilege level checks should be added here.
#
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

  # Before action filter to check if there is any administrator user.
  #
  # * If there isn't at least one, redirect the user to the installation form.
  # * If there is one or more administratos in the system, the petition continues without redirections.
  #
  def check_installation
    if (User.where(:level => User::ADMINISTRATOR_USER).count == 0)
      # No administrator user, redirect!
      redirect_to start_installation_url()
      return
    end
  end

  # Before action filter that applies the locale preferred by the user, 
  # if logged in.
  #
  # If there isn't a logged in user, the default locale is applied.
  #
  def set_locale
    if (user_signed_in? && I18n.available_locales.include?(current_user.lang))
      # If a user is signed in, put the preferred language.
      I18n.locale = current_user.lang
    else
      # If there isn't a logged in user, use the default value
      # defined in config.
      I18n.locale = I18n.default_locale
    end
    return
  end

  # Before action filter to check if the current user has an
  # administrator level of privileges.
  #
  # If the current user hasn't that privilege level, it's redirected
  # to the root path with an error message.
  #
  # [Returns]
  #   A boolean indicating if the privilege requirement is met.
  #
  def check_administrator_user
    result = current_user.is_administrator?

    if (!result)
      # If it doesn't meet the minimum privilege level, redirect.
      flash[:error] = t("ui.error.forbidden")
      redirect_to root_path()
    end

    return result
  end

  # Before action filter to check if the current user has an
  # normal level (or higher) of privileges.
  #
  # If the current user hasn't that privilege level, it's redirected
  # to the root path with an error message.
  #
  # [Returns]
  #   A boolean indicating if the privilege requirement is met.
  #
  def check_normal_user
    result = current_user.is_normal?
    
    if (!result)
      # If it doesn't meet the minimum privilege level, redirect.
      flash[:error] = t("ui.error.forbidden")
      redirect_to root_path()
    end

    return result
  end

  # Before action filter to check if the current user has an
  # normal level (or higher) of privileges.
  #
  # If the current user hasn't that privilege level, it's redirected
  # to the root path with an error message.
  #
  # [Returns]
  #   A boolean indicating if the privilege requirement is met.
  #
  def check_guest_user
    # This will return true always, but it is checked just in case.
    result = current_user.is_guest?

    if (!result)
      # If it doesn't meet the minimum privilege level, redirect.
      flash[:error] = t("ui.error.forbidden")
      redirect_to root_path()
    end

    return result
  end

  private

  # Overwriting the sign_out redirect path to redirect the user to 
  # the login form instead of the root url.
  #
  # This is because the root path requires a logged in user, so it's
  # more correct to redirect the user to the login path.
  #
  # [Returns]
  #   The login path.
  #
  def after_sign_out_path_for(resource_or_scope)
    return session_path(resource_or_scope)
  end
end
