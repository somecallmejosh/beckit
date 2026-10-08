class SettingsController < ApplicationController
  before_action :set_user

  # GET /settings/edit
  def edit
  end

  # PATCH/PUT /settings
  def update
    if @user.update(settings_params)
      redirect_to edit_settings_path, notice: "Settings saved.", status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

  private
    def set_user
      @user = Current.user
    end

    def settings_params
      params.expect(user: [ :name, :preferred_name, :date_of_birth, :avatar, :remove_avatar, :crisis_contact_name, :crisis_contact_phone, :time_zone ])
    end
end
