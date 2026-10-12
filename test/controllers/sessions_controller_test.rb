require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup { @user = User.take }

  test "new" do
    get new_session_path
    assert_response :success
  end

  test "create with valid credentials" do
    post session_path, params: { email_address: @user.email_address, password: "password" }

    assert_redirected_to root_path
    assert cookies[:session_id]
  end

  test "create keeps the session after the browser closes only when asked" do
    post session_path, params: { email_address: @user.email_address, password: "password" }
    assert_no_match(/expires=/i, response.headers["Set-Cookie"].to_s)

    post session_path, params: { email_address: @user.email_address, password: "password", remember_me: "1" }
    assert_match(/session_id=.*expires=/i, response.headers["Set-Cookie"].to_s)
  end

  test "create with invalid credentials" do
    post session_path, params: { email_address: @user.email_address, password: "wrong" }

    assert_redirected_to new_session_path
    assert_nil cookies[:session_id]
  end

  test "destroy" do
    sign_in_as(User.take)

    delete session_path

    assert_redirected_to root_path
    assert_empty cookies[:session_id]

    follow_redirect!
    assert_select "#notice", "You're signed out."
    assert_select "#hero_heading"
  end
end
