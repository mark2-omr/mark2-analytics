Rails.application.config.middleware.use OmniAuth::Builder do
  provider :auth0,
           Rails.application.credentials.auth0.app.client_id,
           Rails.application.credentials.auth0.app.client_secret,
           Rails.application.credentials.auth0.domain,
           callback_path: '/auth/auth0/callback',
           scope: 'openid'

  OmniAuth.config.on_failure =
    Proc.new { |env| OmniAuth::FailureEndpoint.new(env).redirect_to_failure }
end
