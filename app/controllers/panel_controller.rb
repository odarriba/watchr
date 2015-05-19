# Controller with the actions of the main panel with statistics and general data.
# 
class PanelController < ApplicationController
  # Check the privilege level required.
  before_action :check_administrator_user, :only => [:sidekiq]

  # Action to show main panel, which contains basic results information.
  #
  # [URL]
  #   GET /
  #
  # [Parameters]
  #   None.
  #
  def index
    @services = Service.where(:active => true).select{|serv| (serv.host_ids.count > 0)}
    @alert_records = AlertRecord.all.desc(:open).desc(:updated_at).limit(20)
    
    respond_to do |format|
      format.html
      format.js
    end
  end

  # This action shows the sidekiq panel in a frame.
  #
  # It requires administration privileges (as the panel itself).
  #
  # [URL]
  #   GET /sidekiq
  #
  def sidekiq
    respond_to do |format|
      format.html
    end
  end
end
