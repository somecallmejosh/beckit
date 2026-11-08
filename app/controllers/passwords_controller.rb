class PasswordsController < ApplicationController
  allow_unauthenticated_access
  before_action :set_user_by_token, only: %i[ edit update ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_password_path, alert: RATE_LIMITED }

  def new
  end

  def create
    if user = User.find_by(email_address: params[:email_address])
      PasswordsMailer.reset(user).deliver_later
    end

    # Worded the same whether or not the account exists, so the form can't be used to check who has one.
    redirect_to new_session_path, notice: "If there's an account for that email address, a link to reset the password is on its way."
  end

  def edit
  end

  def update
    # has_secure_password ignores a blank password, which would "succeed" without changing anything.
    if params[:password].present? && @user.update(params.permit(:password, :password_confirmation))
      @user.sessions.destroy_all
      redirect_to new_session_path, notice: "Your password is changed. Sign in with the new one."
    else
      @user.errors.add(:password, :blank) if params[:password].blank?
      # Rendered, so the errors sit beside their fields (shared/_new_password_fields).
      render :edit, status: :unprocessable_content
    end
  end

  private
    def set_user_by_token
      @user = User.find_by_password_reset_token!(params[:token])
    rescue ActiveSupport::MessageVerifier::InvalidSignature
      redirect_to new_password_path, alert: "That reset link has expired or was already used. Ask for a new one below."
    end
end
