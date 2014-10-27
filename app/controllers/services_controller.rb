# Controller to perform _Service_ related actions.
#
# It includes service administration actions: create, edit, update and destroy hosts.
#
class ServicesController < ApplicationController
  # Check the privilege level required
  before_action :check_normal_user, :only => [:new, :create, :edit, :update, :destroy, :get_probe_form, :new_host, :delete_host]
  # Check the existence of hosts first
  before_action :check_host_existence, :only => [:index_hosts, :new_host, :delete_host]

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

  # Action to show the service creation form.
  #
  # [URL] 
  #   GET /configuration/services/new
  #
  # [Parameters] 
  #   * *priority* - _(Optional)_ The default priority of the host to create.
  #
  def new
    @service = Service.new

    # If a valid type is received, apply to the host to create.
    check_priority_param
    @service.priority = @priority if(!@priority.blank?)

    # Add custom views paths
    prepend_view_path "app/views/services"
    prepend_view_path "lib/probes/#{@service.probe}/views"

    respond_to do |format|
      format.html
    end
  end

  # Action to create a new service with the data received from the form.
  #
  # [URL] 
  #   POST /configuration/services
  #
  # [Parameters]
  #   * *service* - All the data recolected of the new service.
  #
  def create
    parameters = service_params
    parameters[:probe_config] = params[:probe_config]

    # Apply the params received
    @service = Service.new(parameters)

    respond_to do|format|
      format.html{
        # Can be saved?
        if (@service.save)
          flash[:notice] = t("services.notice.created", :name => @service.name)
          redirect_to service_path(@service)
        else
          # Add custom views paths
          prepend_view_path "app/views/services"
          prepend_view_path "lib/probes/#{@service.probe}/views"

          # If an error raises, show the form again.
          render :action => :new
        end
        return
      }
    end
  end

  # Action to show a the information about an existing service.
  #
  # [URL] 
  #   GET /configuration/services/:id
  #
  # [Parameters]
  #   * *id* - The identificator of the service.
  #
  def show
    load_service
    return if (@service.blank?)

    # Add custom views paths
    prepend_view_path "app/views/services"
    prepend_view_path "lib/probes/#{@service.probe}/views"

    respond_to do|format|
      format.html
    end
  end

  # Action to show a form to edit an existing service.
  #
  # [URL] 
  #   GET /configuration/services/:id/edit
  #
  # [Parameters]
  #   * *id* - The identificator of the service.
  #
  def edit
    load_service
    return if (@service.blank?)

    # Add custom views paths
    prepend_view_path "app/views/services"
    prepend_view_path "lib/probes/#{@service.probe}/views"

    respond_to do|format|
      format.html
    end
  end

  # Action to update an existing service with the data received from the form.
  #
  # [URL] 
  #   PUT /configuration/services/:id
  #   PATCH /configuration/services/:id
  #
  # [Parameters]
  #   * *id* - The identificator of the host.
  #   * *service* - The data recolected for the service.
  #
  def update
    load_service
    return if (@service.blank?)

    parameters = service_params
    parameters[:probe_config] = params[:probe_config] if (!params[:probe_config].blank?)

    respond_to do|format|
      format.html{
        # The service can be updated?
        if (@service.update_attributes(parameters))
          flash[:notice] = t("services.notice.updated", :name => @service.name)
          redirect_to service_path(@service)
        else
          # Add custom views paths
          prepend_view_path "app/views/services"
          prepend_view_path "lib/probes/#{@service.probe}/views"

          # If an error raises, show the form again
          render :action => :edit
        end
        return
      }
    end
  end

  # Action to destroy an existing service in the database.
  #
  # [URL] 
  #   DELETE /configuration/services/:id
  #
  # [Parameters]
  #   * *id* - The identificator of the service.
  #
  def destroy
    load_service
    return if (@service.blank?)

    respond_to do|format|
      format.html{
        # The service can be destroyed?
        if (@service.destroy)
          flash[:notice] = t("services.notice.destroyed", :name => @service.name)
          redirect_to services_path()
        else
          flash[:error] = t("services.error.not_destroyed", :name => @service.name)
          redirect_to service_path(@service)
        end
        return
      }
    end
  end

  # Action to get a probe configuration form using AJAX.
  #
  # [URL] 
  #   * GET /configuration/services/:id/probe_form/:probe
  #   * GET /configuration/services/new/probe_form/:probe
  #
  # [Parameters]
  #   * *id* - The identificator of the service.
  #   * *probe* - The name of the probe.
  #
  def get_probe_form
    if (!params[:id].blank?)
      load_service
      return if (@service.blank?)
    else
      @service = Service.new()
    end

    # Add custom views paths
    prepend_view_path "app/views/services"
    prepend_view_path "lib/probes/#{params[:probe]}/views"

    respond_to do |format|
      format.js
    end
  end

  # Action to index the hosts associated to a service.
  #
  # [URL] 
  #   * GET /configuration/services/:id/hosts
  #
  # [Parameters]
  #   * *id* - The identificator of the service.
  #
  def index_hosts
    load_service
    return if (@service.blank?)

    @hosts = Host.where(:_id.in => @service.host_ids)

    respond_to do |format|
      format.html
    end
  end

  # Action to associate a hosts to a service.
  #
  # [URL] 
  #   * POST /configuration/services/:id/hosts/new
  #
  # [Parameters]
  #   * *id* - The identificator of the service.
  #   * *host_id* - The identificator of the host.
  #
  def new_host
    load_service
    return if (@service.blank?)

    @host = Host.where(:_id => params[:host_id]).first

    if (@host.blank?)
      flash[:error] = t("services.error.host_not_found")
      redirect_to service_hosts_path()
      return
    end

    if (@service.host_ids.include?(@host.id))
      flash[:notice] = t("services.notice.host_already_added", :name => @host.name, :service => @service.name)
      redirect_to service_hosts_path()
      return
    end

    @service.hosts << @host

    respond_to do |format|
      format.html{
        if (@service.save)
          flash[:notice] = t("services.notice.host_added", :name => @host.name, :service => @service.name)
        else
          flash[:error] = t("services.error.host_not_added", :name => @host.name, :service => @service.name)
        end
        redirect_to service_hosts_path()
        return
      }
    end
  end

  # Action to disassociate a hosts to a service.
  #
  # [URL] 
  #   * DELETE /configuration/services/:id/hosts/:host_id
  #
  # [Parameters]
  #   * *id* - The identificator of the service.
  #   * *host_id* - The identificator of the host.
  #
  def delete_host
    load_service
    return if (@service.blank?)

    @host = Host.where(:_id => params[:host_id]).first

    # Does the host exist?
    if (@host.blank?)
      flash[:error] = t("services.error.host_not_found")
      redirect_to service_hosts_path()
      return
    end

    # Disassociate the host from the service
    @service.hosts.delete(@host)

    respond_to do |format|
      format.html{
        if (@service.save)
          flash[:notice] = t("services.notice.host_deleted", :name => @host.name, :service => @service.name)
        else
          flash[:error] = t("services.error.host_not_deleted", :name => @host.name, :service => @service.name)
        end
        redirect_to service_hosts_path()
        return
      }
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

  # Function to check if there is any existing host before executing the actions
  # that are related to service <-> host relation management.
  #
  def check_host_existence
    if (Host.all.count == 0)
      flash[:error] = t("services.error.hosts_not_exist")
      redirect_to :back
    end
    
    return
  end

  # Function lo load a service from the database using *id* parameter in the URL.
  #
  # It returns the Service object and makes it available at @service.
  #
  # [Returns]
  #   A valid _Service_ object or _nil_ if it doesn't exists.
  #
  def load_service
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
    params.require(:service).permit(:name, :description, :active, :priority, :probe, :interval, :clean_interval, :resume)
  end
end
