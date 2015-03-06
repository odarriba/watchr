# Controller with the actions of the main panel with statistics and general data.
# 
class PanelController < ApplicationController
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
    
    respond_to do |format|
      format.html
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
