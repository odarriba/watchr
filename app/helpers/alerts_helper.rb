# Helper functions for _AlertsController_ actions.
#
module AlertsHelper
  # Helper function to get a hash with the valid services for the _Alert_ form.
  #
  # [Returns]
  #   Hash with the type service identificators associated to the their names.
  #
  def alert_services_hash
    result = Hash.new

    Service.all.each do |serv|
      result[serv.name] = serv.id.to_s
    end

    return result
  end

  # Helper function to get a hash with the valid conditions of _Alert_ model.
  #
  # [Returns]
  #   Hash with the condition identificators associated to the translations of the condition names.
  #
  def alert_conditions_hash
    result = Hash.new

    Alert::AVAILABLE_CONDITIONS.each do |cond|
      result[t("alerts.conditions.condition_#{cond.to_s}")] = cond
    end

    return result
  end

  # Helper function to get a hash with the valid targets of _Alert_ model.
  #
  # [Returns]
  #   Hash with the target identificators associated to the translations of the target names.
  #
  def alert_targets_hash
    result = Hash.new

    Alert::AVAILABLE_TARGETS.each do |targ|
      result[t("alerts.targets.target_#{targ.to_s}")] = targ
    end

    return result
  end
end
