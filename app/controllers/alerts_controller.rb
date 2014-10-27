# Controller to perform _Alert_ related actions.
#
# It includes alert administration actions: create, edit, update and destroy hosts.
#
class AlertsController < ApplicationController
  # Check the privilege level required
  before_action :check_normal_user, :only => [:new, :create, :edit, :update, :destroy]

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
