class UsersController < ApplicationController
  # Check the privilege level required.
  before_action :check_administrator_user, :except => [:edit, :update]

  # Action to list all the users in the system.
  # It also allows to search in the users by name and/or e-mail
  #
  # [URL] GET /users
  # [Param :level] The level of the users to show (or nothing to show all).
  #
  def index
    # If a level is passed, check if it's a number and a valid level of privileges.
    if (!params[:level].blank? && params[:level].to_i.to_s == params[:level] && User::LEVELS.include?(params[:level].to_i))
      # Assign the level
      @level = params[:level].to_i

      # Do the query
      @users = User.where(:level => @level)
    else
      # No level required
      @level = nil

      # Do the query
      @users = User.all
    end

    # Pagination ?
    if (params[:page] != nil)
      page = params[:page].to_i
      page = 1 if (page < 1)
    else
      page = 1
    end
    
    @users = @users.page(page)

    respond_to do |format|
      format.html
    end
  end
end
