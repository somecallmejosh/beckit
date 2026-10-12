require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "new" do
    get new_registration_url
    assert_response :success
  end

  test "create with valid params signs the user in" do
    assert_difference("User.count") do
      post registration_url, params: { user: { name: "New User", email_address: "new@example.com", password: "password", password_confirmation: "password" } }
    end

    assert_redirected_to root_url
    assert cookies[:session_id]
  end

  test "create with invalid params" do
    assert_no_difference("User.count") do
      post registration_url, params: { user: { name: "", email_address: "bad", password: "password", password_confirmation: "nope" } }
    end

    assert_response :unprocessable_content
  end
  test "create rejects a short password and says why" do
    assert_no_difference("User.count") do
      post registration_url, params: { user: { name: "New", email_address: "new@example.com", password: "short", password_confirmation: "short" } }
    end

    assert_response :unprocessable_content
    assert_select "#error_explanation li", /too short/
  end

  test "new shows the password rule and links to the privacy page" do
    get new_registration_url
    assert_select "#password_hint", "At least 8 characters."
    assert_select "input[name=?][minlength='8']", "user[password]"
    assert_select "a[href=?]", privacy_path
  end

  test "create cannot grant admin" do
    post registration_url, params: { user: { name: "Sneaky", email_address: "sneaky@example.com", password: "password", password_confirmation: "password", admin: true } }

    assert_not User.find_by(email_address: "sneaky@example.com").admin?
  end
end
