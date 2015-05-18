# Controller to perform _Alert_ related actions.
#
# It includes alert administration actions: create, edit, update and destroy hosts.
#
class AlertsController < ApplicationController
  # Check the privilege level required
  before_action :check_normal_user, :only => [:new, :create, :edit, :update, :destroy, :new_user, :delete_user]
  # Check the existence of services first
  before_action :check_service_existence, :only => [:new, :create, :edit, :update]

  # Action to list the alerts registered in the application.
  # It also allows to search in the alerts by _name_ and/or _description_.
  #
  # [URL] 
  #   GET /alerts
  #
  # [Parameters] 
  #   * *page* - _(Optional)_ The page of results to show.
  #   * *q* - _(Optional)_ A search query to filter alerts.
  #
  def index
    @alerts = Alert.all

    # If an activation status is passed, get the specified alerts
    check_active_param
    @alerts = @alerts.where(:active => @active) if (@active != nil)

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
  #   GET /alerts/new
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
  #   POST /alerts
  #
  # [Parameters]
  #   * *alert* - All the data recolected of the new service.
  #
  def create
    parameters = alert_params
    parameters[:service] = Service.where(:_id => parameters[:service_id]).first
    parameters[:hosts] = Host.where(:_id.in => parameters[:host_ids]).to_a if (!parameters[:host_ids].blank?)

    # Delete string'd id's
    parameters.delete(:service_id)
    parameters.delete(:host_ids)

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
  #   GET /alerts/:id
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
  #   GET /alerts/:id/edit
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
  #   PUT /alerts/:id
  #   PATCH /alerts/:id
  #
  # [Parameters]
  #   * *id* - The identificator of the alert.
  #   * *alert* - The data recolected for the alert.
  #
  def update
    load_alert
    return if (@alert.blank?)

    parameters = alert_params
    parameters[:service] = Service.where(:_id => parameters[:service_id]).first if (!parameters[:service_id].blank?)

    if (!parameters[:host_ids].blank?)
      # Remove removed hosts
      @alert.hosts.select{|h| parameters[:host_ids].include?(h.id.to_s) == false}.each{|h| @alert.hosts.delete(h)}

      # Add the new hosts
      host_ids_add = parameters[:host_ids].select{|h| @alert.host_ids.include?(h) == false}
      Host.where(:_id.in => host_ids_add, :service_ids => parameters[:service_id]).to_a.each do |h|
        @alert.hosts << h
      end
    else
      # Empty the hosts array
      parameters[:hosts] = []
    end

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
  #   DELETE /alerts/:id
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

  # Action to get a selector of hosts to monitor.
  #
  # [URL] 
  #   * GET /alerts/:id/service_hosts/:service_id
  #   * GET /alerts/new/service_hosts/:service_id
  #
  # [Parameters]
  #   * *id* - The identificator of the alert.
  #   * *service_id* - The id of the service selected.
  #
  def get_service_hosts
    if (!params[:id].blank?)
      load_alert
      return if (@alert.blank?)
    else
      @alert = Alert.new()
    end

    @service = Service.where(:_id => params[:service_id]).first

    respond_to do |format|
      format.js
    end
  end

  # Action to index the users subscribed to an alert.
  #
  # [URL] 
  #   * GET /alerts/:id/users
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
  #   * POST /alerts/:id/users/new
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
  #   * DELETE /alerts/:id/users/:user_id
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

  # Action to index the alert records of an alert.
  #
  # [URL] 
  #   * GET /alerts/records/:id
  #
  # [Parameters]
  #   * *id* - The identificator of the alert.
  #
  def index_records
    # If there is an ID passed, try to load the alert
    if (!params[:id].blank?) && (params[:id] != "all")
      @alert = Alert.where(:_id => params[:id]).first
    end

    # if there is an alert loaded, filter the results
    if (!@alert.blank?)
      @alert_records = AlertRecord.where(:alert_id => @alert.id)
    else
      @alert_records = AlertRecord.all
    end

    # Ordering results
    @alert_records = @alert_records.desc(:opened).desc(:updated_at)

    # If a page number is received, save it (if not, the page is the first)
    if (!params[:page].blank?)
      page = params[:page].to_i
      page = 1 if (page < 1)
    else
      page = 1
    end
    
    # Paginate!
    @alert_records = @alert_records.page(page)

    respond_to do |format|
      format.html
    end
  end

  # Action to show a the information about an existing alert record.
  #
  # [URL] 
  #   GET /alerts/record/:id
  #
  # [Parameters]
  #   * *id* - The identificator of the alert record.
  #
  def show_record
    load_alert_record
    return if (@alert_record.blank?)

    respond_to do|format|
      format.html
    end
  end

  protected

  # Function to check the existence of the *active* parameter in the URL.
  # Also checks if the activation status is valid.
  #
  # If the active parameter exists and it's valid, the variable @active is setted.
  #
  # [Returns]
  #   The value of @active (the number received or _nil_)
  #
  def check_active_param
    if (!params[:active].blank?)
      if (params[:active] == true || params[:active] == "true")
        @active = true
      elsif (params[:active] == false || params[:active] == "false")
        @active = false
      end
    end

    return @active
  end

  # Function lo load an alert from the database using *id* parameter in the URL.
  #
  # It returns the Alert object and makes it available at @alert.
  #
  # [Parameters]
  #   * *redirect* - _(Optional)_ If user must be redirected if no alert is found (default: true)
  #
  # [Returns]
  #   A valid _Alert_ object or _nil_ if it doesn't exists.
  #
  def load_alert(redirect = true)
    if (params[:id].blank?)
      @alert = nil
      return @alert
    end

    @alert = Alert.where(:_id => params[:id]).first

    if (@alert.blank? && redirect)
      # If not found, show an error and redirect
      flash[:error] = t("alerts.error.not_found")
      redirect_to alerts_path()
    end

    return @alert
  end

  # Function lo load an alert from the database using *id* parameter in the URL.
  #
  # It returns the Alert object and makes it available at @alert.
  #
  # [Parameters]
  #   * *redirect* - _(Optional)_ If user must be redirected if no alert is found (default: true)
  #
  # [Returns]
  #   A valid _Alert_ object or _nil_ if it doesn't exists.
  #
  def load_alert_record(redirect = true)
    if (params[:id].blank?)
      @alert_record = nil
      return @alert_record
    end

    @alert_record = AlertRecord.where(:_id => params[:id]).first

    if (@alert_record.blank? && redirect)
      # If not found, show an error and redirect
      flash[:error] = t("alerts.error.record_not_found")
      redirect_to alert_records_path()
    end

    return @alert_record
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
    params.require(:alert).permit(:name, :description, :active, :service_id, :condition, :limit, :condition_target, :error_control, :host_ids => [])
  end
end
