class SessionsController < ApplicationController
  def create
    user = User.find_or_create_from_auth(request.env["omniauth.auth"])
    session[:user_id] = user.uid
    log_audit('Sign in')
    redirect_to request.env["omniauth.origin"] || root_url
  end

  def destroy
    log_audit('Sign out')
    reset_session
    request_params = {
      returnTo: root_url,
      client_id: Rails.application.credentials.auth0.app.client_id,
    }
    redirect_to URI::HTTPS.build(
                  host: Rails.application.credentials.auth0.domain,
                  path: "/v2/logout",
                  query: request_params.to_query,
                ).to_s,
                allow_other_host: true
  end

  def failure
    redirect_to root_url
  end
end
