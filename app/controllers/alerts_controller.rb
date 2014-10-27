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
