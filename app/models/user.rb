class User < ApplicationRecord
  belongs_to :group
  before_create :create_auth0_user
  before_destroy :destroy_auth0_user

  def self.find_or_create_from_auth(auth)
    provider = auth[:provider]
    uid = auth[:uid]

    self.find_or_create_by(provider: provider, uid: uid) do |user|
      user.email = auth[:info][:email]
    end
  end

  private

  def auth0_token
    url =
      URI("https://#{Rails.application.credentials.auth0.domain}/oauth/token")

    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    request = Net::HTTP::Post.new(url)
    request["content-type"] = "application/json"
    request.body = {
      client_id: Rails.application.credentials.auth0.m2m.client_id,
      client_secret: Rails.application.credentials.auth0.m2m.client_secret,
      audience: "https://#{Rails.application.credentials.auth0.domain}/api/v2/",
      grant_type: "client_credentials",
    }.to_json
    response = http.request(request)

    return JSON.parse(response.body)["access_token"]
  end

  def create_auth0_user
    url =
      URI("https://#{Rails.application.credentials.auth0.domain}/api/v2/users")
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    request = Net::HTTP::Post.new(url)
    request["Authorization"] = "bearer #{auth0_token}"
    request["content-type"] = "application/json"
    request.body = {
      email: self.email,
      password: SecureRandom.base64(24),
      connection: "Username-Password-Authentication",
      email_verified: true,
    }.to_json
    response = http.request(request)
    self.uid = JSON.parse(response.body)["user_id"]
    self.provider = "auth0"
  end

  def destroy_auth0_user
    url =
      URI(
        "https://#{Rails.application.credentials.auth0.domain}/api/v2/users/#{ERB::Util.url_encode(self.uid)}",
      )
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    request = Net::HTTP::Delete.new(url)
    request["Authorization"] = "bearer #{auth0_token}"
    request["content-type"] = "application/json"
    response = http.request(request)
  end
end
