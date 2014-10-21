# Controller with Installation related actions, used when there isn't
# at least one user with administrato privilege level.
#
# *Note:* If there is at least one administrator user, this actions will be
# redirected to the root path to avoid unwanted re-installations.
#
class InstallationController < ApplicationController
  # Skip authentication and installation check to avoid redirection loops.
  skip_before_action :check_installation
  skip_before_action :authenticate_user!
  # If there is a valid installation, don't do another one.
  before_action :installation_exists?

  # Use devise layout for external pages.
  layout "devise"

  # Action to show a form to get the data needed to
  # perform a valid installation.
  #
  # [URL] 
  #   GET /installation
  #
  # [Parameters] 
  #   None.
  #
  def start
    @user = User.new

    respond_to do |format|
      format.html
    end
  end

  # Action to perform the installation.
  #
  # [URL] 
  #   POST /installation
  #
  # [Parameters] 
  #   * *:user* - Hash with the data needed to create the administrator (_name_ and _email_).
  #
  def apply
    # Check if the data was received and valid
    if (params[:user].blank?)
      # If not, redirect to the form
      redirect_to start_installation_url()
      return
    end

    # Generate random password and apply to a hash with the user configuration
    password = User.generate_random_password()
    user_data = {:name => params[:user][:name], :email => params[:user][:email], :level => User::LEVEL_ADMINISTRATOR, :password => password, :password_confirmation => password}

    @user = User.new(user_data)

    # If the user is valid, clean the user collection
    User.destroy_all if (@user.valid?)

    respond_to do |format|
      format.html {
        # Try to save the new administrator.
        if (@user.save)
          flash[:notice] = t("installation.messages.correct")
          redirect_to new_user_session_path()
        else
          # If there is an error, show the form again.
          render :action => :start
        end
        return
      }
    end
  end

  protected

  # Before filter action to prevent from attemps of performing an installation
  # when another administrator already exists in the database.
  #
  # If exists at least one user with administrator privileges, the user
  # is redirected to the root path.
  #
  def installation_exists?
    if (User.where(:level => User::LEVEL_ADMINISTRATOR).count > 0)
      redirect_to root_path()
      return
    end
  end
end
