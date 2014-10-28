# Controller to perform _Alert_ related actions.
#
# It includes alert administration actions: create, edit, update and destroy hosts.
#
class AlertsController < ApplicationController
  # Check the privilege level required
  before_action :check_normal_user, :only => [:new, :create, :edit, :update, :destroy]
  # Check the existence of services first
  before_action :check_service_existence, :only => [:new, :create, :edit, :update]

  # Action to list the alerts registered in the application.
  # It also allows to search in the alerts by _name_ and/or _description_.
  #
  # [URL] 
  #   GET /configuration/alerts
  #
  # [Parameters] 
  #   * *page* - _(Optional)_ The page of results to show.
  #   * *q* - _(Optional)_ A search query to filter alerts.
  #
  def index
    @alerts = Alert.all

    # If a search query is received, filter the results
    if (!params[:q].blank?)
      # Do the search
      @query = params[:q]
      @alerts = @alerts.where("$or" => [{:name => /#{@query}/i}, {:description => /#{@query}/i}])
    end

    # If a page number is received, save it (if not, the page is the first)
    if (!params[:page].blank?)
      page = params[:page].to_i
      page = 1 if (page < 1)
    else
      page = 1
    end
    
    # Paginate!
    @alerts = @alerts.page(page)

    respond_to do |format|
      format.html
    end
  end

  # Action to show the service creation form.
  #
  # [URL] 
  #   GET /configuration/alerts/new
  #
  def new
    @alert = Alert.new

    respond_to do |format|
      format.html
    end
  end

  # Action to create a new alert with the data received from the form.
  #
  # [URL] 
  #   POST /configuration/alerts
  #
  # [Parameters]
  #   * *alert* - All the data recolected of the new service.
  #
  def create
    parameters = alert_params
    parameters[:service] = Service.where(:_id => parameters[:service]).first

    # Apply the params received
    @alert = Alert.new(parameters)

    respond_to do|format|
      format.html{
        # Can be saved?
        if (@alert.save)
          flash[:notice] = t("alerts.notice.created", :name => @alert.name)
          redirect_to alert_path(@alert)
        else
          # If an error raises, show the form again.
          render :action => :new
        end
        return
      }
    end
  end

  # Action to show a the information about an existing alert.
  #
  # [URL] 
  #   GET /configuration/alerts/:id
  #
  # [Parameters]
  #   * *id* - The identificator of the alert.
  #
  def show
    load_alert
    return if (@alert.blank?)

    respond_to do|format|
      format.html
    end
  end

  # Action to show a form to edit an existing alert.
  #
  # [URL] 
  #   GET /configuration/alerts/:id/edit
  #
  # [Parameters]
  #   * *id* - The identificator of the alert.
  #
  def edit
    load_alert
    return if (@alert.blank?)

    respond_to do|format|
      format.html
    end
  end

  # Action to update an existing alert with the data received from the form.
  #
  # [URL] 
  #   PUT /configuration/alerts/:id
  #   PATCH /configuration/alerts/:id
  #
  # [Parameters]
  #   * *id* - The identificator of the alert.
  #   * *alert* - The data recolected for the alert.
  #
  def update
    load_alert
    return if (@alert.blank?)

    parameters = alert_params
    parameters[:service] = Service.where(:_id => parameters[:service]).first if (!parameters[:service].blank?)

    respond_to do|format|
      format.html{
        # The alert can be updated?
        if (@alert.update_attributes(parameters))
          flash[:notice] = t("alerts.notice.updated", :name => @alert.name)
          redirect_to alert_path(@alert)
        else
          # If an error raises, show the form again
          render :action => :edit
        end
        return
      }
    end
  end

  # Action to destroy an existing alert in the database.
  #
  # [URL] 
  #   DELETE /configuration/alerts/:id
  #
  # [Parameters]
  #   * *id* - The identificator of the alert.
  #
  def destroy
    load_alert
    return if (@alert.blank?)

    respond_to do|format|
      format.html{
        # The alert can be destroyed?
        if (@alert.destroy)
          flash[:notice] = t("alerts.notice.destroyed", :name => @alert.name)
          redirect_to alerts_path()
        else
          flash[:error] = t("alerts.error.not_destroyed", :name => @alert.name)
          redirect_to alert_path(@alert)
        end
        return
      }
    end
  end

  # Action to index the users subscribed to an alert.
  #
  # [URL] 
  #   * GET /configuration/alerts/:id/users
  #
  # [Parameters]
  #   * *id* - The identificator of the alert.
  #
  def index_users
    load_alert
    return if (@alert.blank?)

    # Preload the users
    @users = User.where(:_id.in => @alert.user_ids)

    respond_to do |format|
      format.html
    end
  end

  # Action to subscribe a user to an alert.
  #
  # [URL] 
  #   * POST /configuration/alerts/:id/users/new
  #
  # [Parameters]
  #   * *id* - The identificator of the alert.
  #   * *user_id* - The identificator of the user.
  #
  def new_user
    load_alert
    return if (@alert.blank?)

    @user = User.where(:_id => params[:user_id]).first

    # Do the user exists?
    if (@user.blank?)
      flash[:error] = t("alerts.error.user_not_found")
      redirect_to alert_users_path()
      return
    end

    # is already subscribed?
    if (@alert.user_ids.include?(@user.id))
      flash[:notice] = t("alerts.notice.user_already_added", :name => @user.name, :alert => @alert.name)
      redirect_to alert_users_path()
      return
    end

    # Subscribe it
    @alert.users << @user

    respond_to do |format|
      format.html{
        if (@alert.save)
          flash[:notice] = t("alerts.notice.user_added", :name => @user.name, :alert => @alert.name)
        else
          flash[:error] = t("alerts.error.user_not_added", :name => @user.name, :alert => @alert.name)
        end
        redirect_to alert_users_path()
        return
      }
    end
  end

  # Action to desubscribe a user to an alert.
  #
  # [URL] 
  #   * DELETE /configuration/alerts/:id/users/:user_id
  #
  # [Parameters]
  #   * *id* - The identificator of the alert.
  #   * *user_id* - The identificator of the user.
  #
  def delete_user
    load_alert
    return if (@alert.blank?)

    @user = User.where(:_id => params[:user_id]).first

    # Does the user exist?
    if (@user.blank?)
      flash[:error] = t("alerts.error.user_not_found")
      redirect_to alert_users_path()
      return
    end

    # Disassociate the user from the alert
    @alert.users.delete(@user)

    respond_to do |format|
      format.html{
        if (@alert.save)
          flash[:notice] = t("alerts.notice.user_deleted", :name => @user.name, :alert => @alert.name)
        else
          flash[:error] = t("alerts.error.user_not_deleted", :name => @user.name, :alert => @alert.name)
        end
        redirect_to alert_users_path()
        return
      }
    end
  end

  protected

  # Function lo load an alert from the database using *id* parameter in the URL.
  #
  # It returns the Alert object and makes it available at @alert.
  #
  # [Returns]
  #   A valid _Alert_ object or _nil_ if it doesn't exists.
  #
  def load_alert
    if (params[:id].blank?)
      @alert = nil
      return @alert
    end

    @alert = Alert.where(:_id => params[:id]).first

    if (@alert.blank?)
      # If not found, show an error and redirect
      flash[:error] = t("alerts.error.not_found")
      redirect_to alerts_path()
    end

    return @alert
  end

  # Function to check if there is any existing service before executing 
  # the create/update actions that require at least a service.
  #
  def check_service_existence
    if (Service.all.count == 0)
      flash[:error] = t("alerts.error.services_not_exist")
      redirect_to :back
    end
    
    return
  end

  private

  # Strong parameters method to prevent from massive assignment in the _Alert_ model.
  #
  # [Returns]
  #   The filtered version of *params[:alert]*.
  #
  def alert_params
    params.require(:alert).permit(:name, :description, :active, :service, :condition, :limit, :target)
  end
end
