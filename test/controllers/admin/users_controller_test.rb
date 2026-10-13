require "test_helper"

class Admin::UsersControllerTest < ActionDispatch::IntegrationTest
  test "admins see every user with name, email and membership length" do
    users(:one).update_columns(created_at: 3.months.ago)
    sign_in_as users(:admin)

    get admin_users_url
    assert_response :success
    assert_select "h1", "Users"
    assert_select "#users tbody tr", User.count
    assert_select "##{dom_id(users(:one))}" do
      assert_select "td", text: /User One/
      assert_select "a[href=?]", "mailto:one@example.com"
      assert_select "td", text: /3 months/
    end
    assert_select "header nav[aria-label=Main] a[aria-current=page]", "Users"
  end

  test "non-admins are turned away and don't see the nav link" do
    sign_in_as users(:one)

    get admin_users_url
    assert_redirected_to root_url

    get situations_url
    assert_select "a[href=?]", admin_users_path, count: 0
  end

  test "requires sign-in" do
    get admin_users_url
    assert_redirected_to new_session_url
  end
end
