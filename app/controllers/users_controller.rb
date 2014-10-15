class UsersController < ApplicationController
  # Check the privilege level required.
  before_action :check_administrator_user, :only => [:new, :create, :edit, :update, :destroy]
  before_action :check_normal_user, :only => [:index, :show]
  before_action :check_guest_user, :only => [:preferences]

  # Action to list all the users in the system.
  # It also allows to search in the users by name and/or e-mail
  #
  # [URL] GET /users
  # [Param :level] The level of the users to show (or nothing to show all).
  # [Param :page] The number of the page to show.
  # [Param :q] A string to search for users.
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

  # Action to show a form to create an user.
  #
  # [URL] GET /users/new
  # [Param :level] Optional: The default level of the users to create.
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

  # Action to save a new user with the data received from the new user's form.
  #
  # [URL] POST /users
  # [Param :user] All the parameters of the user.
  #
  def create
    # Apply the params received
    @user = User.new(user_params)

    # Generate an user password
    @user.password = User.generate_random_password

    respond_to do|format|
      format.html{
        # Can be saved?
        if (@user.save)
          flash[:notice] = t("users.notice.created", :email => @user.email)
          redirect_to user_path(@user)
        else
          render :action => :new
        end
        return
      }
    end
  end

  # Action to show the information available of an user.
  #
  # [URL] GET /users/:id
  # [Param :id] The id of the user.
  #
  def show
    load_user
    return if (@user.blank?)

    respond_to do|format|
      format.html
    end
  end

  # Action to show a form to edit an user.
  #
  # [URL] GET /users/:id/edit
  # [Param :id] The id of the user.
  #
  def edit
    load_user
    return if (@user.blank?)

    respond_to do|format|
      format.html
    end
  end

  # Action to update an existing user with the data from the edit form.
  #
  # [URL] PUT /users/:id
  # [Param :id] The id of the user.
  # [Param :user] All the parameters of the user.
  #
  def update
    load_user

    return if (@user.blank?)

    # Read the params and check if the password must be changed
    user_values = user_params
    new_password = (user_values[:change_password] == "true")
    user_values.delete(:change_password)

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
          render :action => :edit
        end
        return
      }
    end
  end

  # Action to destroy an existing user.
  #
  # [URL] DELETE /users/:id
  # [Param :id] The id of the user.
  #
  def destroy
    load_user
    return if (@user.blank?)

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
  # [URL] get /preferences
  #
  def preferences
    @user = current_user

    respond_to do |format|
      format.html
    end
  end

  protected

  # Auxiliar function to check the existence of params[:level].
  # Also checks if the level received is a valid user level.
  #
  # If the level exists and it's valid, the variable @level is setted to these value.
  #
  def check_level_param
    if (!params[:level].blank? && params[:level].to_i.to_s == params[:level] && User.valid_level?(params[:level].to_i))
      @level = params[:level].to_i
    end

    return @level
  end

  # Function lo load a user from the database using params[:id] identificator
  #
  # It returns the User object and makes it available at @user.
  #
  def load_user
    @user = User.where(:_id => params[:id]).first

    if (@user.blank?)
      flash[:error] = t("users.error.not_found")
      redirect_to users_path()
    end

    return @user
  end

  private

  # StrongParameters method to prevent from massive assignment in the User model.
  #
  def user_params
    if (params[:action] == "update")
      params.require(:user).permit(:email, :level, :name, :gravatar_email, :lang, :change_password)
    else
      params.require(:user).permit(:email, :level, :name, :gravatar_email, :lang)
    end
  end
end
