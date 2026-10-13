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

  test "new shows the password rule and links to the privacy page and disclaimer" do
    get new_registration_url
    assert_select "#password_hint", "At least 8 characters."
    assert_select "input[name=?][minlength='8']", "user[password]"
    assert_select "a[href=?]", privacy_path
    assert_select "a[href=?]", disclaimer_path
  end

  test "create cannot grant admin" do
    post registration_url, params: { user: { name: "Sneaky", email_address: "sneaky@example.com", password: "password", password_confirmation: "password", admin: true } }

    assert_not User.find_by(email_address: "sneaky@example.com").admin?
  end

  test "create keeps a supported browser time zone and ignores others" do
    post registration_url, params: { user: { name: "Lee", email_address: "lee@example.com", password: "password", password_confirmation: "password", time_zone: "Europe/London" } }
    assert_equal "Europe/London", User.find_by(email_address: "lee@example.com").time_zone

    post registration_url, params: { user: { name: "Sam", email_address: "sam@example.com", password: "password", password_confirmation: "password", time_zone: "Mars/Olympus" } }
    assert_equal "America/New_York", User.find_by(email_address: "sam@example.com").time_zone
  end

  test "new fills the time zone from the browser" do
    get new_registration_url
    assert_select "input[type=hidden][name=?][data-controller=time-zone]", "user[time_zone]"
  end

  test "errors show under each field and the summary links to them" do
    post registration_url, params: { user: { name: "", email_address: "new@example.com", password: "short", password_confirmation: "short" } }

    assert_select "input#user_name[aria-invalid=true][aria-describedby=user_name_error]"
    assert_select "p#user_name_error.field-error", "Name can't be blank"
    assert_select "input#user_password[aria-describedby=?]", "password_hint user_password_error"
    assert_select "p#user_password_error", /too short/
    assert_select "#error_explanation a[href=?]", "#user_name", "Name can't be blank"
    assert_select "input#user_email_address[aria-invalid]", count: 0
  end
end
