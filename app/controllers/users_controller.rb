class UsersController < ApplicationController
  # Check the privilege level required.
  before_action :check_administrator_user, :except => [:edit, :update]

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
    @user = User.new(user_params)

    @user.password = User.generate_random_password

    respond_to do|format|
      format.html{
        if (@user.save)
          redirect_to user_path(@user)
        else
          render :action => :new
        end
        return
      }
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

  private

    # Using a private method to encapsulate the permissible parameters is
    # just a good pattern since you'll be able to reuse the same permit
    # list between create and update. Also, you can specialize this method
    # with per-user checking of permissible attributes.
    def user_params
      params.require(:user).permit(:email, :level, :name, :gravatar_email, :lang)
    end
end
