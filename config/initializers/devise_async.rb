Devise::Async.setup do |config|
  # Use sidekiq engine
  config.backend = :sidekiq

  # Enable de async mailer
  config.enabled = true

  # Use the default queue
  config.queue = :default
end