require 'digest/md5' # Required to use Gravatar

# User model to store information about the users of the application.
#
# It includes some model logic and verifications.
#
class User
  include Mongoid::Document
  include Mongoid::Timestamps

  ####################
  # NOTE: All the privilege levels must be in a specific order, with less value the most privilege level.
  ####################
  
  # Identificator of Administrator privilege level.
  LEVEL_ADMINISTRATOR = 0
  # Identificator of Normal privilege level.
  LEVEL_NORMAL = 1
  # Identificator of Guest privilege level.
  LEVEL_GUEST = 2

  # Array with available level values
  AVAILABLE_LEVELS = [LEVEL_ADMINISTRATOR, LEVEL_NORMAL, LEVEL_GUEST]

  # Include default devise modules. Others available are:
  # :registarable, :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :recoverable, :rememberable, :trackable, :validatable, :async

  # User data
  field :email,               type: String, default: ""
  field :encrypted_password,  type: String, default: ""
  field :name,                type: String, default: ""
  field :level,               type: Integer, default: 1
  field :lang,                type: Symbol, default: I18n.default_locale

  # Gravatar
  field :gravatar_email,      type: String, default: ""

  # Recoverable
  field :reset_password_token,   type: String
  field :reset_password_sent_at, type: Time

  # Rememberable
  field :remember_created_at, type: Time

  # Trackable
  field :sign_in_count,      type: Integer, default: 0
  field :current_sign_in_at, type: Time
  field :last_sign_in_at,    type: Time
  field :current_sign_in_ip, type: String
  field :last_sign_in_ip,    type: String

  ## Confirmable
  # field :confirmation_token,   type: String
  # field :confirmed_at,         type: Time
  # field :confirmation_sent_at, type: Time
  # field :unconfirmed_email,    type: String # Only if using reconfirmable

  ## Lockable
  # field :failed_attempts, type: Integer, default: 0 # Only if lock strategy is :failed_attempts
  # field :unlock_token,    type: String # Only if unlock strategy is :email or :both
  # field :locked_at,       type: Time

  # Subscription to alerts
  has_and_belongs_to_many :alerts, :dependent => :nullify

  # Validations of the fields added (the devise's default fields have validation with Devise)
  validates_length_of :name, minimum: 2, maximum: 30
  validates_length_of :gravatar_email, minimum: 6, maximum: 255
  validates_numericality_of :level, only_integer: true
  validates_inclusion_of :level, in: User::AVAILABLE_LEVELS
  validates_inclusion_of :lang, in: I18n.available_locales

  # Check Gravatar's e-mail format
  validates_format_of :gravatar_email, with: /[a-z0-9!#$%&'*+\/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+\/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?/

  # The fields must be present
  validates_presence_of :name
  validates_presence_of :gravatar_email
  validates_presence_of :level
  validates_presence_of :lang

  # Before validations, get rid of e-mails
  before_validation :transform_emails

  # After creation, send an e-mail
  after_create :send_welcome_email

  # Function to generate the url of the user's avatar using _Gravatar_
  #
  # [Parameters] 
  # * *size* - The size of the image needed
  #
  # [Returns]
  #   The URL of the image.
  #
  def avatar_url(size=150)
    email_hash = Digest::MD5.hexdigest(self.gravatar_email.downcase)

    protocol = "http"
    protocol = "https" if (Watchr::Application::CONFIG["app"]["use_ssl"] == true)

    return "#{protocol}://www.gravatar.com/avatar/#{email_hash}.png?s=#{size}&d=mm"
  end

  # Function to check if the user has an administrator privilege level.
  #
  # [Returns]
  #   A boolean indicating if the user has it or not.
  #
  def is_administrator?
    return (self.level == User::LEVEL_ADMINISTRATOR)
  end

  # Function to check if the user has a normal privilege level.
  #
  # [Returns]
  #   A boolean indicating if the user has it or not.
  #
  def is_normal?
    return ((self.level == User::LEVEL_NORMAL) || (self.level == User::LEVEL_ADMINISTRATOR))
  end

  # Function to check if the user has a guest privilege level.
  #
  # [Returns]
  #   A boolean indicating if the user has it or not.
  #
  def is_guest?
    # This will return true always, but it is checked just in case.
    return ((self.level == User::LEVEL_GUEST) || (self.level == User::LEVEL_NORMAL) || (self.level == User::LEVEL_ADMINISTRATOR))
  end

  # Function to check if a level identificator is a valid privilege level.
  #
  # [Parameters]
  #   * *level* - The privilege level to check.
  #
  # [Returns]
  #   A boolean indicating if the level received is valid or not.
  #
  def self.valid_level?(level)
    return false if (level.blank?)

    # Is a valid level?
    return User::AVAILABLE_LEVELS.include?(level)
  end

  # Function to generate a random password using upcase and downcase
  # letters and numbers.
  #
  # [Parameters]
  #   * *length* - The length of the password needed.
  #
  # [Returns]
  #   The generated password.
  #
  def self.generate_random_password(length = 8)
    o = [('a'..'z'), ('A'..'Z'), ('0'..'9')].map { |i| i.to_a }.flatten
    return (0...length).map { o[rand(o.length)] }.join
  end

  # Function to avoid the compatibility issues between Devise and Rails 4.1.
  #
  # It tells Rails how to serialize the objecto to be saved in the session.
  #
  def self.serialize_into_session(record) # :nodoc:
    [record.id.to_s, record.authenticatable_salt]
  end

  private

  # This function downcase both e-mail addresses of the _User_ model and, 
  # if no gravatar's e-mail is setted, copies the login e-mail.
  #
  def transform_emails
    self.email.downcase!

    if (self.gravatar_email.blank?)
      self.gravatar_email = self.email
    else
      self.gravatar_email.downcase!
    end
  end

  # After creation method to send to the user it's login details vie e-mail.
  #
  def send_welcome_email
    UserMailer.welcome_email(self).deliver
  end
end
