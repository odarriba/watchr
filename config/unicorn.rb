# Configuration file for Unicorn
require 'yaml'

# Get the environment or applies the production environment by default
env = ENV["RAILS_ENV"] || "production"

# Load configuration file
CONFIG = YAML.load_file("config/watchr.yml")[env]

# Set the number of worker processes to run
worker_processes CONFIG["unicorn"]["working_processes"]
# Timeout to wait for workers
timeout CONFIG["unicorn"]["timeout"]

# User and group to execute the app
user CONFIG["unicorn"]["user"], CONFIG["unicorn"]["group"]

# Preload the app for more speed
preload_app CONFIG["unicorn"]["preload_app"]

# Set the working and shared directory of the app (using capistrano structure)
working_directory "#{CONFIG["unicorn"]["app_directory"]}/current"
shared_path = "#{CONFIG["unicorn"]["app_directory"]}/shared"

# Listen in a file socket
listen "#{shared_path}/unicorn.socket", :backlog => 128

# PID of the server
pid "#{shared_path}/shared/pids/unicorn.pid"

# Save error and info logs
stderr_path "#{shared_path}/log/unicorn.stderr.log"
stdout_path "#{shared_path}/log/unicorn.stdout.log"

# Things to do before forking the app
before_fork do |server, worker|
  # If there is an active ActiveRecord connection, disconnect it first.
  if defined?(ActiveRecord::Base)
    ActiveRecord::Base.connection.disconnect!
  end

  # If there is an old PID (used for hot swap between deployed versions),
  # send a QUIT signal
  old_pid = "#{shared_path}/shared/pids/unicorn.pid.oldbin"
  if File.exists?(old_pid) && server.pid != old_pid
    begin
      Process.kill("QUIT", File.read(old_pid).to_i)
    rescue Errno::ENOENT, Errno::ESRCH
    end
  end
end

# Things to do after forking the app
after_fork do |server, worker|
  # If Active record is used, stablish the new connection
  if defined?(ActiveRecord::Base)
    ActiveRecord::Base.establish_connection
    ActiveRecord::Base.verify_active_connections! 
  end
end