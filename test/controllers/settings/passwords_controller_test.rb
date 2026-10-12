require "test_helper"

class Settings::PasswordsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in_as @user
  end

  test "changes the password and signs out other sessions" do
    other = @user.sessions.create!
    patch settings_password_url, params: { password_challenge: "password", password: "a new password", password_confirmation: "a new password" }

    assert_redirected_to edit_settings_url
    assert @user.reload.authenticate("a new password")
    assert_not Session.exists?(other.id)
    assert Session.exists?(Current.session.id)
  end

  test "rejects a wrong current password" do
    patch settings_password_url, params: { password_challenge: "wrong", password: "a new password", password_confirmation: "a new password" }

    assert_response :unprocessable_content
    assert_select "#error_explanation li", "Current password is invalid"
    assert_select "input[name=password_challenge][autofocus]"
    assert @user.reload.authenticate("password")
  end

  test "rejects a missing challenge or a blank new password" do
    patch settings_password_url, params: { password: "a new password", password_confirmation: "a new password" }
    assert_response :unprocessable_content

    patch settings_password_url, params: { password_challenge: "password", password: "", password_confirmation: "" }
    assert_response :unprocessable_content
    assert_select "#error_explanation li", "Password can't be blank"
    assert @user.reload.authenticate("password")
  end

  test "keeps the profile form free of password errors" do
    patch settings_password_url, params: { password_challenge: "password", password: "short", password_confirmation: "short" }

    assert_select "#error_explanation", count: 1
    assert_select "input[name=?][value=?]", "user[name]", @user.name
  end
end
