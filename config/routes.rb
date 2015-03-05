require 'sidekiq/web'

Rails.application.routes.draw do
  devise_for :users, :path => '', :path_names => {:sign_in => 'login', :sign_out => 'logout'}

  root 'panel#index'

  # Error links
  get "/404", :to => "application#error_not_found"
  get "/422", :to => "application#error_unprocessable"
  get "/500", :to => "application#error_internal"

  # Installation operations
  get '/installation' => 'installation#start', :as => :start_installation
  post '/installation' => 'installation#apply', :as => :apply_installation

  # Users operations
  resources :users
  get '/preferences' => 'users#preferences', :as => :user_preferences
  put '/preferences' => 'users#save_preferences'
  patch '/preferences' => 'users#save_preferences'

  # Monitoring operations
  scope '/monitoring' do
    get '/' => 'monitoring#index', :as => :monitoring
    get '/sidekiq' => 'monitoring#sidekiq', :as => :sidekiq_monitoring
    get '/service(/:id)' => 'monitoring#service', :as => :service_monitoring
    get '/service/:id/data' => 'monitoring#service_data', :as => :data_service_monitoring
  end

  scope '/configuration' do
    # Hosts operations
    resources :hosts

    # Services operations
    resources :services
    get 'services/new/probe_form/:probe' => 'services#get_probe_form'
    get 'services/:id/probe_form/:probe' => 'services#get_probe_form', :as => :service_probe_form
    get 'services/:id/hosts' => 'services#index_hosts', :as => :service_hosts
    post 'services/:id/host/new' => 'services#new_host', :as => :new_service_host
    delete 'services/:id/hosts/:host_id' => 'services#delete_host', :as => :delete_service_host

    # Alerts operations
    resources :alerts
    get 'alerts/:id/users' => 'alerts#index_users', :as => :alert_users
    post 'alerts/:id/users/new' => 'alerts#new_user', :as => :new_alert_user
    delete 'alerts/:id/users/:user_id' => 'alerts#delete_user', :as => :delete_alert_user
  end

  authenticate :user, lambda { |u| u.is_administrator? } do
    mount Sidekiq::Web => '/sidekiq'
  end

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
