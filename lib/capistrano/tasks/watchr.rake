namespace :watchr do
  desc "Upload configuration"
  task :upload_config do
    on roles(:web) do |host|
      upload!("config/watchr.yml", "#{shared_path}/config/watchr.yml", :via => :scp)
    end
  end
end