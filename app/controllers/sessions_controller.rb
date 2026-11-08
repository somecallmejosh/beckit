class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_session_path, alert: RATE_LIMITED }

  def new
  end

  def create
    if user = User.authenticate_by(params.permit(:email_address, :password))
      start_new_session_for user, remember: params[:remember_me] == "1"
      redirect_to after_authentication_url
    else
      # Rendered rather than redirected, so the email address stays filled in (and out of the URL).
      flash.now[:alert] = "That email address and password don't match. Check them and try again."
      render :new, status: :unprocessable_content
    end
  end

  def destroy
    terminate_session
    redirect_to root_path, notice: "You're signed out.", status: :see_other
  end
end
