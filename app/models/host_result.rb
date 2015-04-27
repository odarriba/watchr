# HostResult model to store information about individual results fetched
# from the realization of a probe over a concrete host.
#
# Includes relations, fields, auxiliar functions and verifications.
#
class HostResult
  include Mongoid::Document

  # Symbol that indicates a valid result
  STATUS_OK = :ok
  # Symbol that indicates an invalid result
  STATUS_ERROR = :error
  # Symbol taht indicates an inactive host result
  STATUS_INACTIVE = :inactive

  # Array with the available statuses
  AVAILABLE_STATUSES = [STATUS_OK, STATUS_ERROR, STATUS_INACTIVE]

  # Fields of the result
  field :status,      :type => Symbol, :default => HostResult::STATUS_OK
  field :error,       :type => String, :default => ""
  field :value,       :type => Float, :default => nil

  validates_inclusion_of :status, in: HostResult::AVAILABLE_STATUSES
  validates_presence_of :status
  validates_presence_of :host

  validate :check_status

  # Assigned to a host
  belongs_to :host, :inverse_of => nil

  # It's embedded in a Result object
  embedded_in :parent, :polymorphic => true

  # Function to know if the result of this host is an error
  #
  # [Returns]
  #   A boolean that indicates if the result for this host is an error or not.
  #
  def is_error?
    return (self.status == HostResult::STATUS_ERROR)
  end

  # Function to know if the result of this host is valid
  #
  # [Returns]
  #   A boolean that indicates if the result for this host is valid or not.
  #
  def is_ok?
    return (self.status == HostResult::STATUS_OK)
  end

  # Function to know if the result of this host is valid
  #
  # [Returns]
  #   A boolean that indicates if the result for this host is valid or not.
  #
  def is_inactive?
    return (self.status == HostResult::STATUS_INACTIVE)
  end

  # Function to get the timestamp of the result.
  #
  # [Returns]
  #   A Time object with the timestamp of the result.
  #
  def timestamp
    return result.created_at
  end

  protected

  # Validation function to check the result, error and value
  # fields during the save of a HostResult
  #
  # [Returns]
  #   A boolean that indicates if everything was valid or not.
  #
  def check_status
    if (self.status == HostResult::STATUS_OK)
      # A valid result must have a value.
      if (self.value.blank?)
        # Return an error if no value is present
        errors.add(:value, 'valid result must have a value')
        return false
      else
        # If the value is present, clean the error msg
        self.error = ""
        # Round the reuslt
        self.value = self.value.round(4)
      end
    elsif (self.status == HostResult::STATUS_ERROR)
      self.value = nil
    elsif (self.status == HostResult::STATUS_INACTIVE)
      self.value = nil
      self.error = nil
    else
      # Result type undefined???
      errors.add(:result, "the result is undefined")
      return false
    end

    # If everything goes well, return true
    return true
  end
end
