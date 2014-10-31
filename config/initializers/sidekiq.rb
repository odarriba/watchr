Sidekiq.configure_server do |config|
  config.redis = { 
    url: "redis://#{Watchr::Application::CONFIG["redis"]["host"]}:#{Watchr::Application::CONFIG["redis"]["port"]}/#{Watchr::Application::CONFIG["redis"]["db"]}", 
    namespace: Watchr::Application::CONFIG["redis"]["namespace"] 
  }
  config.poll_interval = 1
end

Sidekiq.configure_client do |config|
  config.redis = { 
    url: "redis://#{Watchr::Application::CONFIG["redis"]["host"]}:#{Watchr::Application::CONFIG["redis"]["port"]}/#{Watchr::Application::CONFIG["redis"]["db"]}", 
    namespace: Watchr::Application::CONFIG["redis"]["namespace"] 
  }
  config.poll_interval = 1
end

# :nodoc: all
# This hack is needed to avoid an undocummented use
# of Sidekiq::Web in routes.rb file
#
module Sidekiq
end