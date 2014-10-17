# Controller with the actions of the main panel with statistics and general data.
# 
class PanelController < ApplicationController
  # Dummy function to show a fake (yet) panel
  #
  # [URL]
  #   GET /
  #
  # [Parameters]
  #   None.
  #
  def index
    respond_to do |format|
      format.html
    end
  end
end
