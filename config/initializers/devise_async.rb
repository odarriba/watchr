Devise::Async.setup do |config|
  # Use sidekiq engine
  config.backend = :sidekiq

  # Enable de async mailer
  config.enabled = true

  # Use the default queue
  config.queue = :default
end

# This module is used to fix the Devise's default mailer to
# use the preference language of the user.
#
module Devise
  # The class to modify is Mailer
  #
  class Mailer < ActionMailer::Base
    # Function to send the reset password instructions.
    3
    def reset_password_instructions(record, token, opts={})
      # Get the original locale and set the user's one.
      @previous_local = I18n.locale
      I18n.locale = record.lang

      super

      # Return to the original locale.
      I18n.locale = @previous_local
    end
  end
end