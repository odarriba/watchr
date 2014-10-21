# Controller to perform _User_ related actions.
#
# It includes user administration actions and preference management
# for logged in users.
#
class UsersController < ApplicationController
  # Check the privilege level required.
  before_action :check_administrator_user, :only => [:new, :create, :edit, :update, :destroy]
  before_action :check_normal_user, :only => [:index, :show]
  before_action :check_guest_user, :only => [:preferences]

  # Action to list all the users in the application.
  # It also allows to search in the users by _name_ and/or _e-mail_
  #
  # [URL] 
  #   GET /users
  #
  # [Parameters] 
  #   * *level* - _(Optional)_ The privilege level of the users to show.
  #   * *page* - _(Optional)_ The page of results to show.
  #   * *q* - _(Optional)_ A search query to filter users.
  #
  def index
    @users = User.all

    # If a level is passed, check if it's a number and a valid level of privileges.
    check_level_param
    @users = @users.where(:level => @level) if (!@level.blank?)

    # If a search query is received, filter the results
    if (!params[:q].blank?)
      # Do the search
      @query = params[:q]
      @users = @users.where("$or" => [{:name => /#{@query}/i}, {:email => /#{@query}/i}])
    end

    # If a page number is received, save it (if not, the page is the first)
    if (!params[:page].blank?)
      page = params[:page].to_i
      page = 1 if (page < 1)
    else
      page = 1
    end
    
    # Paginate!
    @users = @users.page(page)

    respond_to do |format|
      format.html
    end
  end

  # Action to show the user creation form.
  #
  # [URL] 
  #   GET /users/new
  #
  # [Parameters] 
  #   * *level* - _(Optional)_ The default level of the user to create.
  #
  def new
    @user = User.new

    # If a valid level is received, apply to the user to create.
    check_level_param
    @user.level = @level if(!@level.blank?)

    respond_to do |format|
      format.html
    end
  end

  # Action to create a new user with the data received from the form.
  #
  # [URL] 
  #   POST /users
  #
  # [Parameters]
  #   * *user* - All the data recolected of the new user.
  #
  def create
    # Apply the params received
    @user = User.new(user_params)

    # Generate an user password.
    @user.password = User.generate_random_password

    respond_to do|format|
      format.html{
        # Can be saved?
        if (@user.save)
          flash[:notice] = t("users.notice.created", :email => @user.email)
          redirect_to user_path(@user)
        else
          # If an error raises, show the form again.
          render :action => :new
        end
        return
      }
    end
  end

  # Action to show the information available about an user.
  #
  # [URL] 
  #   GET /users/:id
  #
  # [Parameters]
  #   * *id* - The identificator of the user.
  #
  def show
    load_user
    return if (@user.blank?)

    respond_to do|format|
      format.html
    end
  end

  # Action to show a form to edit an existing user.
  #
  # [URL] 
  #   GET /users/:id/edit
  #
  # [Parameters]
  #   * *id* - The identificator of the user.
  #
  def edit
    load_user
    return if (@user.blank?)

    respond_to do|format|
      format.html
    end
  end

  # Action to update an existing user with the data received from the form.
  #
  # [URL] 
  #   PUT /users/:id
  #   PATCH /users/:id
  #
  # [Parameters]
  #   * *id* - The identificator of the user.
  #   * *user* - The data recolected for the user.
  #
  def update
    load_user

    return if (@user.blank?)

    # Read the params and check if the password must be changed
    user_values = user_params
    new_password = (user_values[:change_password] == "true")

    # Delete the field of change password.
    user_values.delete(:change_password)
    user_values.delete(:level) if (@user.id == current_user.id)

    # Change the password if needed
    user_values[:password] = User::generate_random_password if (new_password)

    respond_to do|format|
      format.html{
        # The user can be updated?
        if (@user.update_attributes(user_values))
          # Send an e-mail of password changed if needed
          UserMailer.change_password_email(@user).deliver if (new_password)

          flash[:notice] = t("users.notice.updated", :email => @user.email)
          redirect_to user_path(@user)
        else
          # If an error raises, show the form again
          render :action => :edit
        end
        return
      }
    end
  end

  # Action to destroy an existing user from the database.
  #
  # [URL] 
  #   DELETE /users/:id
  #
  # [Parameters]
  #   * *id* - The identificator of the user.
  #
  def destroy
    load_user
    return if (@user.blank?)

    if (@user.id == current_user.id)
      flash[:error] = t("users.error.destroy_yourself")
      redirect_to user_path(@user)
      return
    end

    respond_to do|format|
      format.html{
        # The user can be destroyed?
        if (@user.destroy)
          flash[:notice] = t("users.notice.destroyed", :email => @user.email)
          redirect_to users_path()
        else
          flash[:error] = t("users.error.not_destroyed", :email => @user.email)
          redirect_to user_path(@user)
        end
        return
      }
    end
  end

  # Action to show a form to change the preferences of the current user.
  #
  # [URL] 
  #   GET /preferences
  #
  # [Parameters]
  #   None.
  #
  def preferences
    @user = current_user
    @mode = "general"

    respond_to do |format|
      format.html
    end
  end

  # Action to save the new preferences of the current user.
  #
  # [URL] 
  #   PUT /preferences
  #   PATCH /preferences
  #
  # [Parameters]
  #   * *mode* - The mode of the preferences form (_general_ or _password_)
  #   * *user* - The preferences of the current user's account.
  #
  def save_preferences
    @user = current_user
    @mode = params[:mode]

    user_values = user_params

    # Check user's password
    if (!current_user.valid_password?(user_params[:current_password]))
      @user.errors[:current_password]=true
      render :action => :preferences
      return
    end

    # Delete the current password from the data received
    user_values.delete(:current_password)

    respond_to do |format|
      format.html{
        # Try to update the attributes
        if (@user.update_attributes(user_values))
          flash[:notice] = t("users.notice.preferences_updated") if (@mode == "general")
          flash[:notice] = t("users.notice.password_updated") if (@mode == "password")

          redirect_to root_path()
        else
          # If an error raises, show the form again
          render :action => :preferences
        end

        return
      }
    end
  end

  protected

  # Function to check the existence of the *level* parameter in the URL.
  # Also checks if the level received is a valid privilege level of _User_ model.
  #
  # If the level exists and it's valid, the variable @level is setted to these value.
  #
  # [Returns]
  #   The value of @level (the number received or _nil_)
  #
  def check_level_param
    if (!params[:level].blank? && params[:level].to_i.to_s == params[:level] && User.valid_level?(params[:level].to_i))
      @level = params[:level].to_i
    end

    return @level
  end

  # Function lo load a user from the database using *id* parameter in the URL.
  #
  # It returns the User object and makes it available at @user.
  #
  # [Returns]
  #   A valid _User_ object or _nil_ if it doesn't exists.
  #
  def load_user
    @user = User.where(:_id => params[:id]).first

    if (@user.blank?)
      # If not found, show an error and redirect
      flash[:error] = t("users.error.not_found")
      redirect_to users_path()
    end

    return @user
  end

  private

  # Strong parameters method to prevent from massive assignment in the _User_ model.
  #
  # [Returns]
  #   The filtered version of *params[:user]*.
  #
  def user_params
    if (params[:action] == "update")
      params.require(:user).permit(:email, :level, :name, :gravatar_email, :lang, :change_password)
    elsif (params[:action] == "save_preferences")
      # Password update
      if (params[:mode] == "password")
        params.require(:user).permit(:password, :password_confirmation, :current_password)
      else # General preferences update
        params.require(:user).permit(:email, :name, :gravatar_email, :lang, :current_password)
      end
    else
      params.require(:user).permit(:email, :level, :name, :gravatar_email, :lang)
    end
  end
end
