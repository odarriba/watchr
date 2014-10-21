# Host model to store information about the hosts to monitor.
#
# Includes fields, host type definitions and verifications.
#
class Host
  include Mongoid::Document
  include Mongoid::Timestamps

  # Router host type value
  TYPE_ROUTER = 0
  # Switch host type value
  TYPE_SWITCH = 1
  # Server host type value
  TYPE_SERVER = 2
  # Computer host type value
  TYPE_COMPUTER = 3
  # Generic host type value
  TYPE_GENERIC = 4

  # Array with the available types of a host
  AVAILABLE_TYPES = [TYPE_ROUTER, TYPE_SWITCH, TYPE_SERVER, TYPE_COMPUTER, TYPE_GENERIC]
  
  # Fields of the model
  field :name,          :type => String, :default => ""
  field :description,   :type => String, :default => ""
  field :address,       :type => String, :default => ""
  field :type,          :type => Integer, :default => Host::TYPE_GENERIC

  # Validations of type and content
  validates_length_of :name, :minimum => 2, :maximum => 30
  validates_numericality_of :type, only_integer: true
  validates_inclusion_of :type, in: AVAILABLE_TYPES
  validates_uniqueness_of :address
  validate :check_address

  # Validations to check the presence of required fields
  validates_presence_of :name
  validates_presence_of :address
  validates_presence_of :type

  # Function to get the IP address of the host.
  #
  # [Returns]
  #   A string with IP address resolved, or nil if it fails to resolve.
  #
  def ip_address
    begin
      return Resolv.getaddress(self.address)
    rescue Resolv::ResolvError
      return nil
    end
  end

  # Function to check if the host is a router.
  #
  # [Returns]
  #   A boolean that indicates if the host is a router.
  #
  def is_router?
    return (self.type == Host::TYPE_ROUTER)
  end

  # Function to check if the host is a switch.
  #
  # [Returns]
  #   A boolean that indicates if the host is a switch.
  #
  def is_switch?
    return (self.type == Host::TYPE_SWITCH)
  end

  # Function to check if the host is a server.
  #
  # [Returns]
  #   A boolean that indicates if the host is a server.
  #
  def is_server?
    return (self.type == Host::TYPE_SERVER)
  end

  # Function to check if the host is a computer.
  #
  # [Returns]
  #   A boolean that indicates if the host is a computer.
  #
  def is_computer?
    return (self.type == Host::TYPE_COMPUTER)
  end

  # Function to check if the host type is generic.
  #
  # [Returns]
  #   A boolean that indicates if the host type is generic.
  #
  def is_generic?
    return (self.type == Host::TYPE_GENERIC)
  end

  protected

  # Validation to check if the content of the :address field is
  # a valid IP or can be resolved to an IP.
  #
  # [Returns]
  #   A boolean that indicates if the address is valid.
  #
  def check_address
    begin
      # Try to resolve the address
      ip = Resolv.getaddress(self.address)
      return true
    rescue Resolv::ResolvError
      # If an error raises, add it to the response
      errors.add(:address, 'invalid address')
      return false
    end
  end
end
