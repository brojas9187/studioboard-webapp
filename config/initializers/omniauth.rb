app_url = ENV["APP_URL"].presence
app_url ||= "https://#{ENV["RAILWAY_PUBLIC_DOMAIN"]}" if ENV["RAILWAY_PUBLIC_DOMAIN"].present?

if app_url.present?
  OmniAuth.config.full_host = app_url.delete_suffix("/")
elsif Rails.env.development?
  OmniAuth.config.full_host = "http://localhost:3000"
end

if ENV["GOOGLE_CLIENT_ID"].present? && ENV["GOOGLE_CLIENT_SECRET"].present?
  Rails.application.config.middleware.use OmniAuth::Builder do
    provider :google_oauth2,
             ENV.fetch("GOOGLE_CLIENT_ID"),
             ENV.fetch("GOOGLE_CLIENT_SECRET"),
             {
               scope: "openid,email,profile",
               prompt: "select_account",
               image_aspect_ratio: "square",
               image_size: 128
             }
  end
end
