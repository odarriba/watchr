Sidekiq.configure_server do |config|
  config.redis = { 
    url: "redis://#{Watchr::Application::CONFIG["redis"]["host"]}:#{Watchr::Application::CONFIG["redis"]["port"]}/#{Watchr::Application::CONFIG["redis"]["db"]}", 
    namespace: Watchr::Application::CONFIG["redis"]["namespace"] 
  }
end