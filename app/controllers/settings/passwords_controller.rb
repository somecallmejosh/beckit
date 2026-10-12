class Settings::PasswordsController < ApplicationController
  rate_limit to: 10, within: 3.minutes, only: :update, with: -> { redirect_to edit_settings_path, alert: "Try again later." }

  # PATCH /settings/password
  # Validated on a separate copy of the user so the profile form on the same page stays clean.
  def update
    @password_user = User.find(Current.user.id)

    if params[:password].present? && @password_user.update(password_params)
      Current.user.sessions.where.not(id: Current.session.id).destroy_all
      redirect_to edit_settings_path, notice: "Password changed. Any other devices have been signed out.", status: :see_other
    else
      @password_user.errors.add(:password, :blank) if params[:password].blank?
      @user = Current.user
      render "settings/edit", status: :unprocessable_content
    end
  end

  private
    # A blank challenge is still checked, so it can't be skipped by leaving the field out.
    def password_params
      params.permit(:password, :password_confirmation).merge(password_challenge: params[:password_challenge].to_s)
    end
end
