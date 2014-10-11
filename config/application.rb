require File.expand_path('../boot', __FILE__)

require "action_controller/railtie"
require "action_mailer/railtie"
require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Watchr
  class Application < Rails::Application
    CONFIG = YAML.load_file("#{Rails.root}/config/watchr.yml")[Rails.env]

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    config.time_zone = CONFIG["app"]["time_zone"]

    # E-mail sending configuration
    config.action_mailer.delivery_method = :smtp
    config.action_mailer.smtp_settings = {
      address:              CONFIG["email"]["smtp"]["host"],
      port:                 CONFIG["email"]["smtp"]["port"],
      domain:               CONFIG["email"]["smtp"]["domain"],
      user_name:            CONFIG["email"]["smtp"]["username"],
      password:             CONFIG["email"]["smtp"]["password"],
      authentication:       CONFIG["email"]["smtp"]["authentication"],
      ssl:                  CONFIG["email"]["smtp"]["enable_ssl"],
      enable_starttls_auto: CONFIG["email"]["smtp"]["enable_starttls"]  
    }

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    config.i18n.load_path += Dir[Rails.root.join('config', 'locales', '**', '*.{rb,yml}').to_s]
    config.i18n.default_locale = CONFIG["app"]["default_language"]

    # SASS configuration
    config.sass.preferred_syntax = :sass
    config.sass.line_comments = false
    config.sass.cache = false

    # By default, use SASS and plain JS.
    config.app_generators.stylesheet_engine :sass
    config.app_generators.javascript_engine :js
  end
end
