require "securerandom"

class GoogleOauthAuthenticator
  class Error < StandardError; end

  def initialize(auth_hash:)
    @auth = auth_hash.to_h.with_indifferent_access if auth_hash.present?
  end

  def call
    raise Error, I18n.t("flash.oauth.google_failed") if @auth.blank?
    raise Error, I18n.t("flash.oauth.google_missing_identity") if provider.blank? || uid.blank?
    raise Error, I18n.t("flash.oauth.google_missing_email") if email.blank?

    user = User.find_by(oauth_provider: provider, oauth_uid: uid) ||
           User.find_by("lower(email) = ?", email) ||
           User.new(email: email)

    assign_identity!(user)
    user.save!
    user
  end

  private

  def provider
    @auth[:provider].to_s
  end

  def uid
    @auth[:uid].to_s
  end

  def email
    @auth.dig(:info, :email).to_s.strip.downcase
  end

  def name
    @auth.dig(:info, :name).to_s.strip
  end

  def image
    @auth.dig(:info, :image).to_s.strip
  end

  def assign_identity!(user)
    assign_generated_password!(user) if user.new_record? && user.password_digest.blank?

    user.email = email
    user.name = name.presence || user.name.presence || fallback_name
    user.oauth_provider = provider
    user.oauth_uid = uid
    user.avatar_url = image.presence if user.respond_to?(:avatar_url=)
  end

  def assign_generated_password!(user)
    generated_password = SecureRandom.base58(User::MINIMUM_PASSWORD_LENGTH + 24)
    user.password = generated_password
    user.password_confirmation = generated_password
  end

  def fallback_name
    email.split("@").first.to_s.tr("._", " ").split.map(&:capitalize).join(" ")
  end
end
