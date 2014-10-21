# Controller to perform _Host_ related actions.
#
# It includes host administration actions: create, edit, update and destroy hosts.
#
class HostsController < ApplicationController
  # Action to list the hosts registered in the application.
  # It also allows to search in the hosts by _name_, _description_ and/or _address_
  #
  # [URL] 
  #   GET /monitoring/hosts
  #
  # [Parameters] 
  #   * *type* - _(Optional)_ The type oh hosts to show.
  #   * *page* - _(Optional)_ The page of results to show.
  #   * *q* - _(Optional)_ A search query to filter hosts.
  #
  def index
    @hosts = Host.all

    # If a type of host is passed, check if it's a number and a valid host type.
    check_type_param
    @hosts = @hosts.where(:type => @type) if (!@type.blank?)

    # If a search query is received, filter the results
    if (!params[:q].blank?)
      # Do the search
      @query = params[:q]
      @hosts = @hosts.where("$or" => [{:name => /#{@query}/i}, {:description => /#{@query}/i}, {:address => /#{@query}/i}])
    end

    # If a page number is received, save it (if not, the page is the first)
    if (!params[:page].blank?)
      page = params[:page].to_i
      page = 1 if (page < 1)
    else
      page = 1
    end
    
    # Paginate!
    @hosts = @hosts.page(page)

    respond_to do |format|
      format.html
    end
  end

  protected

  # Function to check the existence of the *type* parameter in the URL.
  # Also checks if the host type received is a valid host type of _Host_ model.
  #
  # If the type exists and it's valid, the variable @type is setted to these value.
  #
  # [Returns]
  #   The value of @type (the number received or _nil_)
  #
  def check_type_param
    if (!params[:type].blank? && params[:type].to_i.to_s == params[:type] && Host.valid_type?(params[:type].to_i))
      @type = params[:type].to_i
    end

    return @type
  end
end
