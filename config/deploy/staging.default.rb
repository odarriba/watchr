# Staging configuration
# ------------------------------------
# server 'example.com',
#   user: 'user_name',
#   roles: %w{web app},
#   ssh_options: {
#     user: 'user_name', # overrides user setting above
#     keys: %w(/home/user_name/.ssh/id_rsa),
#     auth_methods: %w(publickey password)
#     # password: 'please use keys'
#   }

server 'example.com',
  user: 'user_name',
  roles: %w{web app},
  ssh_options: {
    user: 'user_name', # overrides user setting above
    # keys: %w(/home/user_name/.ssh/id_rsa),
    # auth_methods: %w(publickey password)
    password: 'please use keys'
  }

# Configuration of deploy
set :git_url, "git@github.com:odarriba/watchr.git"
set :app_dir, "/directory/to/install/on/remote"