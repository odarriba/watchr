# Controller with Monitoring-related actions for administration
# use.
#
# Also, it's the entry point from the navbar to _HostsController_,
# _ServicesController_ and _AlertsController_ actions.
#
class MonitoringController < ApplicationController
  # This is a dummy view at this stage of development
  #
  # [URL]
  #   GET /monitoring
  #
  def index
    respond_to do |format|
      format.html
    end
  end
end
