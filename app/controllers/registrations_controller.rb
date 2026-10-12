class RegistrationsController < ApplicationController
  allow_unauthenticated_access
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_registration_path, alert: "Try again later." }

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)

    if @user.save
      start_new_session_for @user
      redirect_to root_path, notice: "Welcome, #{@user.name}!"
    else
      render :new, status: :unprocessable_content
    end
  end

  private
    # The browser's time zone, when it's one we support; otherwise the column default.
    def user_params
      params.expect(user: [ :name, :email_address, :password, :password_confirmation, :time_zone ]).tap do |permitted|
        permitted.delete(:time_zone) unless permitted[:time_zone].in?(ActiveSupport::TimeZone.all.map { it.tzinfo.name })
      end
    end
end
