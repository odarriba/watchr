set :application, "watchr"

set :scm, :git
set :repo_url,  -> {fetch(:git_url)}
set :deploy_to, -> {fetch(:app_dir)}
set :branch, 'master'
set :git_shallow_clone, 1

set :ssh_options, {
  forward_agent: true,
  port: 22
}

set :foreman_app, "watchr"
set :log_level, :info

set :pty, true

set :default_env, { RAILS_ENV: "production" }

set :linked_files, %w{config/watchr.yml}
set :linked_dirs, %w{bin log tmp/pids vendor/bundle public/system}

SSHKit.config.command_map[:rake]  = "bundle exec rake"
SSHKit.config.command_map[:rails] = "bundle exec rails"

# Number of releases to store on the server
set :keep_releases, 5

namespace :deploy do
  before "check:linked_files", "watchr:upload_config"
  after :finishing, "deploy:cleanup"
  after :finishing, "deploy:restart"

  desc "Zero-downtime restart of service"
  task :restart do
    on roles(:web) do |host|
      sudo "stop #{fetch(:foreman_app)}"
      sudo "start #{fetch(:foreman_app)}"
    end
  end

  desc "Start service"
  task :start do
    on roles(:web) do |host|
      sudo "start #{fetch(:foreman_app)}"
    end
  end

  desc "Stop service"
  task :stop do
    on roles(:web) do |host|
      sudo "stop #{fetch(:foreman_app)}"
    end
  end

  desc "Install foreman"
  task :install_foreman do
    on roles(:web) do |host|
      execute "cd #{current_path}; sudo bundle exec foreman export -a #{fetch(:foreman_app)} -u #{host.user} -d #{fetch(:deploy_to)}/current upstart /etc/init/"
      execute "sudo mkdir -m 777 -p /var/log/#{fetch(:foreman_app)}"
    end
  end

end