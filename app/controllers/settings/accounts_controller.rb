class Settings::AccountsController < ApplicationController
  rate_limit to: 10, within: 3.minutes, only: :destroy, with: -> { redirect_to edit_settings_path, alert: "Try again later." }

  # DELETE /settings/account
  # Removes the user with their sessions, entries and photo.
  def destroy
    if Current.user.authenticate(params[:password].to_s)
      Current.user.destroy!
      cookies.delete(:session_id)
      redirect_to root_path, notice: "Your account and all of your entries have been deleted.", status: :see_other
    else
      @user = Current.user
      @delete_error = "That password isn't right, so nothing was deleted."
      render "settings/edit", status: :unprocessable_content
    end
  end
end
