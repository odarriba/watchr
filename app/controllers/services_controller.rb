# Controller to perform _Service_ related actions.
#
# It includes service administration actions: create, edit, update and destroy hosts.
#
class ServicesController < ApplicationController
  # Action to list the services registered in the application.
  # It also allows to search in the services by _name_, _description_ and/or _probe_
  #
  # [URL] 
  #   GET /configuration/services
  #
  # [Parameters] 
  #   * *priority* - _(Optional)_ The priority of the services to show.
  #   * *page* - _(Optional)_ The page of results to show.
  #   * *q* - _(Optional)_ A search query to filter services.
  #
  def index
    @services = Service.all

    # If a type of host is passed, check if it's a number and a valid host type.
    check_priority_param
    @services = @services.where(:priority => @priority) if (!@priority.blank?)

    # If a search query is received, filter the results
    if (!params[:q].blank?)
      # Do the search
      @query = params[:q]
      @services = @services.where("$or" => [{:name => /#{@query}/i}, {:description => /#{@query}/i}, {:probe => /#{@query}/i}])
    end

    # If a page number is received, save it (if not, the page is the first)
    if (!params[:page].blank?)
      page = params[:page].to_i
      page = 1 if (page < 1)
    else
      page = 1
    end
    
    # Paginate!
    @services = @services.page(page)

    respond_to do |format|
      format.html
    end
  end

  protected

  # Function to check the existence of the *priority* parameter in the URL.
  # Also checks if the priority received is a valid riority of _Service_ model.
  #
  # If the priority exists and it's valid, the variable @priority is setted to these value.
  #
  # [Returns]
  #   The value of @priority (the number received or _nil_)
  #
  def check_priority_param
    if (!params[:priority].blank? && params[:priority].to_i.to_s == params[:priority] && Service.valid_priority?(params[:priority].to_i))
      @priority = params[:priority].to_i
    end

    return @priority
  end

  # Function lo load a service from the database using *id* parameter in the URL.
  #
  # It returns the Service object and makes it available at @service.
  #
  # [Returns]
  #   A valid _Service_ object or _nil_ if it doesn't exists.
  #
  def load_host
    if (params[:id].blank?)
      @service = nil
      return @service
    end

    @service = Service.where(:_id => params[:id]).first

    if (@service.blank?)
      # If not found, show an error and redirect
      flash[:error] = t("services.error.not_found")
      redirect_to services_path()
    end

    return @service
  end

  private

  # Strong parameters method to prevent from massive assignment in the _Service_ model.
  #
  # [Returns]
  #   The filtered version of *params[:service]*.
  #
  def service_params
    params.require(:service).permit(:name, :description, :probe, :interval, :clean_interval, :priority, :resume)
  end
end
