require 'digest/md5' # Required to use Gravatar

class User
  include Mongoid::Document
  include Mongoid::Timestamps

  # Diferent levels of users
  ADMINISTRATOR = 0
  USER = 1
  GUEST = 2

  # Include default devise modules. Others available are:
  # :registarable, :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :recoverable, :rememberable, :trackable, :validatable

  # User data
  field :email,               type: String, default: ""
  field :encrypted_password,  type: String, default: ""
  field :name,                type: String, default: ""
  field :level,               type: Integer, default: 1

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

  # Validations of the fields added (the devise's default fields have validation with Devise)
  validates_length_of :name, minimum: 3, maximum: 30
  validates_length_of :gravatar_email, minimum: 6, maximum: 255
  validates_numericality_of :level, greater_than_or_equal_to: 0
  validates_numericality_of :level, less_than_or_equal_to: 2
  validates_numericality_of :level, only_integer: true

  # Check Gravatar's e-mail format
  validates_format_of :gravatar_email, with: /[a-z0-9!#$%&'*+\/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+\/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?/

  # The fields must be present
  validates_presence_of :name
  validates_presence_of :gravatar_email
  validates_presence_of :level

  # Before validations, get rid of e-mails
  before_validation :transform_emails

  # After creation, send an e-mail
  after_create :send_welcome_email

  # Returns the url of the user's avatar using Gravatar
  #
  # [size] The size of the image needed.
  #
  def avatar_url(size=150)
    email_hash = Digest::MD5.hexdigest(self.email.downcase)

    protocol = "http"
    protocol = "https" if (Watchr::Application::CONFIG["app"]["use_ssl"] == true)

    return "#{protocol}://www.gravatar.com/avatar/#{email_hash}.png?s=#{size}&d=mm"
  end

  # :nodoc:
  # Function to avoid the compatibility issues between Devise and Rails 4.1
  #
  def self.serialize_from_session(key, salt)
    record = to_adapter.get(key[0]["$oid"])
    record if record && record.authenticatable_salt == salt
  end

  private

  # It downcase both e-mail addresses stored and, if no gravatar's e-mail is setted,
  # it copy the user's one.
  #
  def transform_emails
    self.email.downcase!

    if (self.gravatar_email.blank?)
      self.gravatar_email = self.email
    else
      self.gravatar_email.downcase!
    end
  end

  def send_welcome_email
    UserMailer.welcome_email(self).deliver
  end
end
