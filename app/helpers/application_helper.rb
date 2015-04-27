# Helper functions for _ApplicationController_ actions.
#
module ApplicationHelper
  # Types of alerts defined in Bootstrap
  ALERT_TYPES = [:success, :info, :warning, :danger]

  # Function to translate the flash messages into HTML code
  # using Bootstrap classes for alerts.
  #
  # [Returns]
  #   HTML code with the flash messages.
  #
  def bootstrap_flash
    flash_messages = []
    flash.each do |type, message|
      # Skip empty messages, e.g. for devise messages set to nothing in a locale file.
      next if message.blank?

      type = type.to_sym

      # translate some types into Bootstrap-likely types
      type = :success if type == :notice
      type = :danger  if type == :alert
      type = :danger  if type == :error
      next unless ALERT_TYPES.include?(type)

      Array(message).each do |msg|
        text = content_tag(:div,
          content_tag(:button, raw("&times;"),
            :class => "close",
            "data-dismiss" => "alert",
            "aria-hidden" => "true",
            "type" => "button") +
            msg.html_safe,
            :class => "alert fade in alert-#{type} alert-dismissable")
        flash_messages << text if msg
      end
    end
    flash_messages.join("\n").html_safe
  end

  def service_status_badge(status)
    return "<span class='badge'>#{service_status_text(status)}</span>".html_safe
  end

  def service_status_text(status)
    if (status == Service::STATUS_OK)
      return "<strong class='text-success'>#{t("services.status.ok").upcase}</strong>".html_safe
    elsif (status == Service::STATUS_ERROR)
      return "<strong class='text-danger'>#{t("services.status.error").upcase}</strong>".html_safe
    elsif (status == Service::STATUS_WARNING)
      return "<strong class='text-warning'>#{t("services.status.warning").upcase}</strong>".html_safe
    end
    
    return "<strong class='text-info'>#{t("services.status.unknown").upcase}</strong>".html_safe
  end
end
