# Controller to perform _Host_ related actions.
#
# It includes host administration actions: create, edit, update and destroy hosts.
#
class HostsController < ApplicationController
  # Check the privilege level required
  before_action :check_normal_user, :only => [:new, :create, :edit, :update, :destroy]

  # Action to list the hosts registered in the application.
  # It also allows to search in the hosts by _name_, _description_ and/or _address_
  #
  # [URL] 
  #   GET /configuration/hosts
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

  # Action to show the host creation form.
  #
  # [URL] 
  #   GET /configuration/hosts/new
  #
  # [Parameters] 
  #   * *type* - _(Optional)_ The default type of the host to create.
  #
  def new
    @host = Host.new

    # If a valid type is received, apply to the host to create.
    check_type_param
    @host.type = @type if(!@type.blank?)

    respond_to do |format|
      format.html
    end
  end

  # Action to create a new user with the data received from the form.
  #
  # [URL] 
  #   POST /configuration/hosts
  #
  # [Parameters]
  #   * *host* - All the data recolected of the new host.
  #
  def create
    # Apply the params received
    @host = Host.new(host_params)

    respond_to do|format|
      format.html{
        # Can be saved?
        if (@host.save)
          flash[:notice] = t("hosts.notice.created", :name => @host.name)
          redirect_to host_path(@host)
        else
          # If an error raises, show the form again.
          render :action => :new
        end
        return
      }
    end
  end

  # Action to show the information available about a host.
  #
  # [URL] 
  #   GET /configuration/hosts/:id
  #
  # [Parameters]
  #   * *id* - The identificator of the host.
  #
  def show
    load_host
    return if (@host.blank?)

    respond_to do|format|
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

  # Function lo load a host from the database using *id* parameter in the URL.
  #
  # It returns the Host object and makes it available at @host.
  #
  # [Returns]
  #   A valid _Host_ object or _nil_ if it doesn't exists.
  #
  def load_host
    @host = Host.where(:_id => params[:id]).first

    if (@host.blank?)
      # If not found, show an error and redirect
      flash[:error] = t("hosts.error.not_found")
      redirect_to hosts_path()
    end

    return @host
  end

  private

  # Strong parameters method to prevent from massive assignment in the _Host_ model.
  #
  # [Returns]
  #   The filtered version of *params[:host]*.
  #
  def host_params
    params.require(:host).permit(:name, :address, :type, :description)
  end
end
