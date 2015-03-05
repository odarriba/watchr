# Controller with Monitoring-related actions for administration
# use.
#
# Also, it's the entry point from the navbar to _HostsController_,
# _ServicesController_ and _AlertsController_ actions.
#
class MonitoringController < ApplicationController
  # Check that the user is an administrator before executing sidekiq action.
  before_action :check_administrator_user, :only => [:sidekiq]

  # Tis action shows an overall results page with a small piece of information per
  # service.
  #
  # [URL]
  #   GET /monitoring
  #
  def index
    @services = Service.where(:active => true).select{|serv| (serv.host_ids.count > 0)}

    respond_to do |format|
      format.html
    end
  end

  # Action to view the results from the probes over a service.
  #
  # [URL] 
  #   GET /monitoring/service/:id
  #
  # [Parameters]
  #   * *id* - The identificator of the service.
  #
  def service
    if (!params[:id].blank?)
      # Load the service from the database
      @service = Service.where(:_id => params[:id]).first

      if (@service.blank?)
        # If no service item found, show an error
        flash[:error] = t("services.error.not_found")
      end

      if (!@service.active)
        # If the service isn't active, show an error.
        flash[:error] = t("services.error.not_active")
        
        redirect_to service_monitoring_path()
        return
      end
    end

    respond_to do |format|
      format.html
    end
  end

  # Action to get the data of the results from the probes over a service.
  #
  # [URL] 
  #   GET /monitoring/service/:id/data
  #
  # [Parameters]
  #   * *id* - The identificator of the service.
  #   * *last* - The ID of the last result obtained
  #
  def service_data
    respond_to do |format|
      format.json
    end
  end


  # This action shows the sidekiq panel in a frame.
  #
  # It requires administration privileges (as the panel itself).
  #
  # [URL]
  #   GET /monitoring/sidekiq
  #
  def sidekiq
    respond_to do |format|
      format.html
    end
  end
end
