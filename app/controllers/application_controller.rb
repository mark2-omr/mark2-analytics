class ApplicationController < ActionController::Base
  helper_method :current_user, :user_signed_in?

  private

  def authenticate_user!
    redirect_to root_url unless session[:user_id]
  end

  def current_user
    return unless session[:user_id]

    @current_user ||= User.find_by(uid: session[:user_id])
  end

  def user_signed_in?
    !!session[:user_id]
  end

  def admin_required
    redirect_to root_url unless current_user.admin
  end

  def manager_required
    redirect_to root_url unless current_user.manager
  end
end
