require "test_helper"

class Settings::AccountsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in_as @user
  end

  test "deletes the account, entries and sessions with the right password" do
    assert_difference -> { User.count } => -1, -> { Situation.count } => -@user.situations.count do
      delete settings_account_url, params: { password: "password" }
    end

    assert_redirected_to root_url
    assert_empty cookies[:session_id]
    assert_equal 0, Session.where(user_id: @user.id).count

    follow_redirect!
    assert_select "#notice", /account and all of your entries have been deleted/
  end

  test "deleting the account also removes recently deleted entries" do
    trashed = situations(:one)
    trashed.trash!

    delete settings_account_url, params: { password: "password" }
    assert_not Situation.exists?(trashed.id)
  end

  test "keeps everything with the wrong password" do
    assert_no_difference -> { User.count } do
      delete settings_account_url, params: { password: "wrong" }
    end

    assert_response :unprocessable_content
    assert_select "[role=alert]", /nothing was deleted/
    assert_select "#delete_account_password[autofocus][aria-invalid]"
  end

  test "settings confirms with the entry count and offers an export" do
    get edit_settings_url
    assert_select "form[action=?][data-turbo-confirm*=?]", settings_account_path, "1 entry"
    assert_select "a[href=?]", situations_path(format: :csv)
  end
end
