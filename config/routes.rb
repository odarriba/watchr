require 'sidekiq/web'

Rails.application.routes.draw do
  devise_for :users, :path => '', :path_names => {:sign_in => 'login', :sign_out => 'logout'}

  root 'panel#index'
  get '/sidekiq' => 'panel#sidekiq', :as => :sidekiq_panel

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

  # Hosts operations
  resources :hosts
  get 'hosts/:id/results' => 'hosts#results', :as => :results_host
  get 'hosts/:id/alert_records' => 'hosts#alert_records', :as => :alert_records_host

  # Services operations
  resources :services
  get 'services/new/probe_form/:probe' => 'services#get_probe_form'
  get 'services/:id/probe_form/:probe' => 'services#get_probe_form', :as => :service_probe_form
  get 'services/:id/results' => 'services#results', :as => :results_service
  get 'services/:id/results/data' => 'services#results_data', :as => :results_data_service
  get 'services/:id/results/hosts' => 'services#hosts_results', :as => :hosts_results_service
  get 'services/:id/results/:host_id' => 'services#host_results', :as => :host_results_service
  get 'services/:id/results/:host_id/data' => 'services#host_results_data', :as => :host_results_data_service
  get 'services/:id/hosts' => 'services#index_hosts', :as => :service_hosts
  post 'services/:id/host/new' => 'services#new_host', :as => :new_service_host
  delete 'services/:id/hosts/:host_id' => 'services#delete_host', :as => :delete_service_host

  # Alerts operations
  resources :alerts
  get 'alerts/records/:id' => 'alerts#index_records', :as => :alert_records
  get 'alerts/record/:id' => 'alerts#show_record', :as => :alert_record
  get 'alerts/new/service_hosts/:service_id' => 'alerts#get_service_hosts'
  get 'alerts/:id/service_hosts/:service_id' => 'alerts#get_service_hosts', :as => :service_hosts_alert
  get 'alerts/:id/users' => 'alerts#index_users', :as => :alert_users
  post 'alerts/:id/users/new' => 'alerts#new_user', :as => :new_alert_user
  delete 'alerts/:id/users/:user_id' => 'alerts#delete_user', :as => :delete_alert_user

  authenticate :user, lambda { |u| u.is_administrator? } do
    mount Sidekiq::Web => '/sidekiq_full'
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
