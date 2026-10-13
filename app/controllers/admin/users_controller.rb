class Admin::UsersController < ApplicationController
  require_admin

  # GET /admin/users
  def index
    @users = User.with_attached_avatar.order(created_at: :desc)
  end
end
