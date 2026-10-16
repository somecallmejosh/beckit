require "test_helper"

class SettingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in_as @user
  end

  test "requires authentication" do
    sign_out
    get edit_settings_url
    assert_redirected_to new_session_url
  end

  test "the plant grows a stage for every ten finished entries" do
    @user.update_column(:finished_entries_count, 1)
    get edit_settings_url
    assert_select "#plant p", text: /finished 1 entry\.\s+9 more until it's planted\./
    assert_includes milestone_images, "seed-locked"

    @user.update_column(:finished_entries_count, 10)
    get edit_settings_url
    assert_select "#plant p", text: /finished 10 entries\.\s+10 more until it's a sprout\./
    assert_includes milestone_images, "seed"
    assert_includes milestone_images, "sprout-locked"
  end

  test "shows the current time zone selected" do
    get edit_settings_url
    assert_response :success
    assert_select "select[name=?] option[selected]", "user[time_zone]", count: 1
    assert_select "select[name=?] option[selected][value=?]", "user[time_zone]", "America/New_York"
  end

  test "updates the time zone" do
    patch settings_url, params: { user: { time_zone: "America/Chicago" } }
    assert_redirected_to edit_settings_url
    assert_equal "America/Chicago", @user.reload.time_zone
  end

  test "rejects an unknown time zone" do
    patch settings_url, params: { user: { time_zone: "Nowhere/Special" } }
    assert_response :unprocessable_content
    assert_equal "America/New_York", @user.reload.time_zone
  end

  test "cannot change admin, email or password" do
    patch settings_url, params: { user: { time_zone: "America/Chicago", admin: true, email_address: "new@example.com", password: "changed" } }
    @user.reload
    assert_not @user.admin?
    assert_equal "one@example.com", @user.email_address
    assert @user.authenticate("password")
  end

  test "dates use the chosen time zone" do
    @user.update!(time_zone: "America/Los_Angeles")
    patch situation_step_url(situations(:one), "what-happened"), params: { situation: { date: "2026-10-01T21:00" } }
    assert_equal Time.utc(2026, 10, 2, 4, 0), situations(:one).reload.date
  end

  test "updates profile fields" do
    patch settings_url, params: { user: { name: "Joshua Briley", preferred_name: "Josh", date_of_birth: "1985-06-01" } }
    assert_redirected_to edit_settings_url
    @user.reload
    assert_equal [ "Joshua Briley", "Josh", Date.new(1985, 6, 1) ], [ @user.name, @user.preferred_name, @user.date_of_birth ]
  end

  test "uploads and removes an avatar" do
    patch settings_url, params: { user: { avatar: fixture_file_upload("avatar.png", "image/png") } }
    assert_redirected_to edit_settings_url
    assert @user.reload.avatar.attached?

    get edit_settings_url
    assert_select "header img[alt=?]", @user.name
    assert_select "input[type=checkbox][name=?]", "user[remove_avatar]"

    perform_enqueued_jobs { patch settings_url, params: { user: { remove_avatar: "1" } } }
    assert_not @user.reload.avatar.attached?
  end

  test "rejects a non-image avatar" do
    patch settings_url, params: { user: { avatar: fixture_file_upload("notes.txt", "text/plain") } }
    assert_response :unprocessable_content
    assert_not @user.reload.avatar.attached?
  end

  test "header shows initials and first name without an avatar" do
    get edit_settings_url
    assert_select "header a[href=?]", edit_settings_path, text: /UO\s*User One\s*User/
  end

  test "footer shows the default line, or the saved crisis contact" do
    get edit_settings_url
    assert_select "footer a[href='tel:988']"

    @user.update!(crisis_contact_name: "Samaritans", crisis_contact_phone: "116 123")
    get edit_settings_url
    assert_select "footer a[href='tel:116123']", text: "116 123"
    assert_select "footer p", text: /contact Samaritans at/
  end

  private
    # Stage drawings on the page, e.g. "seed" or "sprout-locked" (asset digests stripped).
    def milestone_images
      css_select("img[src*='milestones/']").map { it["src"][%r{milestones/([a-z-]+?)(?:-[0-9a-f]{8,})?\.svg}, 1] }
    end
end
