class InstallationController < ApplicationController
  skip_before_action :check_installation
  skip_before_action :authenticate_user!
  before_action :installation_exists?

  layout "devise"

  # Action to show a form to get the data needed to
  # perform a valid installation.
  #
  # [Method] GET /installation
  #
  def start
    @user = User.new

    respond_to do |format|
      format.html
    end
  end

  # Action to perform the installation.
  #
  # [Method] POST /installation
  #
  def apply
    # Check if the data was received and valid
    if (params[:user].blank?)
      redirect_to start_installation_url()
      return
    end

    password = User.generate_random_password()
    user_data = {:name => params[:user][:name], :email => params[:user][:email], :level => User::ADMINISTRATOR, :password => password, :password_confirmation => password}

    @user = User.new(user_data)

    respond_to do |format|
      format.html {
        if (@user.save)
          flash[:notice] = t("installation.messages.correct")
          redirect_to new_user_session_path()
        else
          flash[:error] = t("installation.messages.error")
          render :action => :start
        end
        return
      }
    end
  end

  protected

  # Function to protect from attemps of performing an installation
  # when another administrator already exists in the database.
  #
  def installation_exists?
    if (User.where(:level => User::ADMINISTRATOR).count > 0)
      redirect_to root_url()
      return
    end
  end
end
