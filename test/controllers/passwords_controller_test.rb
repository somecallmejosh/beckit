require "test_helper"

class PasswordsControllerTest < ActionDispatch::IntegrationTest
  setup { @user = User.take }

  test "new" do
    get new_password_path
    assert_response :success
  end

  test "create" do
    post passwords_path, params: { email_address: @user.email_address }
    assert_enqueued_email_with PasswordsMailer, :reset, args: [ @user ]
    assert_redirected_to new_session_path

    follow_redirect!
    assert_notice "a link to reset the password is on its way"
  end

  test "create for an unknown user redirects but sends no mail" do
    post passwords_path, params: { email_address: "missing-user@example.com" }
    assert_enqueued_emails 0
    assert_redirected_to new_session_path

    follow_redirect!
    assert_notice "a link to reset the password is on its way"
  end

  test "edit" do
    get edit_password_path(@user.password_reset_token)
    assert_response :success
  end

  test "edit with invalid password reset token" do
    get edit_password_path("invalid token")
    assert_redirected_to new_password_path

    follow_redirect!
    assert_notice "reset link has expired or was already used"
  end

  test "update" do
    assert_changes -> { @user.reload.password_digest } do
      put password_path(@user.password_reset_token), params: { password: "new password", password_confirmation: "new password" }
      assert_redirected_to new_session_path
    end

    follow_redirect!
    assert_notice "Your password is changed"
  end

  test "update with non matching passwords" do
    token = @user.password_reset_token
    assert_no_changes -> { @user.reload.password_digest } do
      put password_path(token), params: { password: "long enough", password_confirmation: "but different" }
      assert_response :unprocessable_content
    end

    assert_select "#error_explanation li a[href='#password_confirmation']", /Password confirmation doesn't match/
    assert_select "#password_confirmation[aria-invalid=true][aria-describedby=password_confirmation_error]"
    assert_select "#password_confirmation_error.field-error", /doesn't match/
  end

  test "update with a too-short password" do
    token = @user.password_reset_token
    assert_no_changes -> { @user.reload.password_digest } do
      put password_path(token), params: { password: "short", password_confirmation: "short" }
      assert_response :unprocessable_content
    end

    assert_select "#password[aria-invalid=true][aria-describedby='password_hint password_error']"
    assert_select "#password_error", /too short/
  end

  test "update with a blank password changes nothing and says so" do
    token = @user.password_reset_token
    assert_no_changes -> { @user.reload.password_digest } do
      put password_path(token), params: { password: "", password_confirmation: "" }
      assert_response :unprocessable_content
    end

    assert_select "#password_error", /can't be blank/
  end

  private
    def assert_notice(text)
      assert_select "div", /#{text}/
    end
end
