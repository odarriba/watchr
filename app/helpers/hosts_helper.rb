# Helper functions for _HostsController_ actions.
#
module HostsHelper
  # Helper function to get a hash with the valid host types of _Host_ model.
  #
  # [Returns]
  #   Hash with the type identificators associated to the translations of the host type names.
  #
  def host_types_hash
    result = Hash.new

    Host::AVAILABLE_TYPES.each do |level|
      result[t("hosts.types.type_#{level}")] = level
    end

    return result
  end
end
