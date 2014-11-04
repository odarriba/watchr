# Controller with Monitoring-related actions for administration
# use.
#
# Also, it's the entry point from the navbar to _HostsController_,
# _ServicesController_ and _AlertsController_ actions.
#
class MonitoringController < ApplicationController
  # Check that the user is an administrator before executing sidekiq action.
  before_action :check_administrator_user, :only => [:sidekiq]

  # This is a dummy view at this stage of development
  #
  # [URL]
  #   GET /monitoring
  #
  def index
    @services = Service.where(:active => true)

    respond_to do |format|
      format.html
    end
  end

  # This action shows the sidekiq panel in a frame.
  #
  # It requires administration privileges (as the panel itself).
  #
  # [URL]
  #   GET /monitoring/sidekiq
  def sidekiq
    respond_to do |format|
      format.html
    end
  end
end
