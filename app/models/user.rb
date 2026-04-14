require "openssl"
require "securerandom"

class User < ApplicationRecord
  MINIMUM_PASSWORD_LENGTH = 8

  attr_reader :password
  attr_accessor :password_confirmation

  has_many :memberships, dependent: :destroy
  has_many :organizations, through: :memberships
  has_many :created_projects, class_name: "Project", foreign_key: :creator_id, inverse_of: :creator
  has_many :created_tasks, class_name: "Task", foreign_key: :creator_id, inverse_of: :creator
  has_many :assigned_tasks, class_name: "Task", foreign_key: :assignee_id, inverse_of: :assignee

  before_validation :normalize_email

  validates :name, presence: true
  validates :email, presence: true,
                    format: { with: URI::MailTo::EMAIL_REGEXP },
                    uniqueness: { case_sensitive: false }
  validates :oauth_uid, uniqueness: { scope: :oauth_provider }, allow_blank: true
  validates :password, presence: true,
                       length: { minimum: MINIMUM_PASSWORD_LENGTH },
                       if: :password_required?
  validate :password_confirmation_matches

  def password=(new_password)
    @password = new_password
    return if new_password.blank?

    self.password_salt = SecureRandom.hex(16)
    self.password_digest = self.class.digest_password(new_password, password_salt)
  end

  def authenticate(candidate_password)
    return false if candidate_password.blank? || password_digest.blank? || password_salt.blank?

    attempted_digest = self.class.digest_password(candidate_password, password_salt)
    ActiveSupport::SecurityUtils.secure_compare(attempted_digest, password_digest) ? self : false
  end

  def display_name
    name.presence || email
  end

  def google_account?
    oauth_provider == "google_oauth2" && oauth_uid.present?
  end

  def self.digest_password(password, salt)
    iterations = Rails.env.test? ? 1_000 : 120_000
    OpenSSL::PKCS5.pbkdf2_hmac(password, salt, iterations, 32, "sha256").unpack1("H*")
  end

  private

  def normalize_email
    self.email = email.to_s.strip.downcase
  end

  def password_required?
    password_digest.blank? || password.present?
  end

  def password_confirmation_matches
    return if password.blank? && password_confirmation.blank?
    return if password == password_confirmation

    errors.add(:password_confirmation, :confirmation, attribute: self.class.human_attribute_name(:password))
  end
end
