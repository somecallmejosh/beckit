require "test_helper"

class UserTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "downcases and strips email_address" do
    user = User.new(email_address: " DOWNCASED@EXAMPLE.COM ")
    assert_equal("downcased@example.com", user.email_address)
  end

  test "requires a name" do
    user = User.new(email_address: "new@example.com", password: "password")
    assert_not user.valid?
    assert_includes user.errors[:name], "can't be blank"
  end

  test "requires a valid email_address" do
    user = User.new(name: "New", email_address: "not-an-email", password: "password")
    assert_not user.valid?
    assert_includes user.errors[:email_address], "is invalid"
  end

  test "requires a unique email_address" do
    user = User.new(name: "New", email_address: users(:one).email_address.upcase, password: "password")
    assert_not user.valid?
    assert_includes user.errors[:email_address], "has already been taken"
  end

  test "time_zone defaults to Eastern" do
    assert_equal "America/New_York", User.new.time_zone
  end

  test "rejects an unknown time_zone" do
    user = users(:one)
    user.time_zone = "Mars/Olympus_Mons"
    assert_not user.valid?
    assert_includes user.errors[:time_zone], "is not included in the list"
  end

  test "first_name prefers the preferred name, then the first word of the name" do
    user = User.new(name: "Joshua Briley")
    assert_equal "Joshua", user.first_name
    user.preferred_name = "Josh"
    assert_equal "Josh", user.first_name
  end

  test "initials use the first and last words" do
    assert_equal "JB", User.new(name: "joshua lee briley").initials
    assert_equal "J", User.new(name: "Josh").initials
  end

  test "birthday_today? including Feb 29 in non-leap years" do
    user = User.new(date_of_birth: Date.new(1990, 10, 7))
    assert user.birthday_today?(Date.new(2026, 10, 7))
    assert_not user.birthday_today?(Date.new(2026, 10, 8))

    leap = User.new(date_of_birth: Date.new(2000, 2, 29))
    assert leap.birthday_today?(Date.new(2027, 2, 28))
    assert leap.birthday_today?(Date.new(2028, 2, 29))
    assert_not leap.birthday_today?(Date.new(2028, 2, 28))
    assert_not User.new.birthday_today?
  end

  test "date_of_birth must be between 1900 and today" do
    user = users(:one)
    user.date_of_birth = Date.current + 1
    assert_not user.valid?
    user.date_of_birth = Date.new(1899, 12, 31)
    assert_not user.valid?
    user.date_of_birth = Date.new(1985, 6, 1)
    assert user.valid?
  end

  test "crisis contact needs both a name and a valid phone" do
    user = users(:one)
    user.crisis_contact_name = "Samaritans"
    assert_not user.valid?
    assert_includes user.errors[:crisis_contact_phone], "is needed for your crisis contact"

    user.crisis_contact_phone = "call me"
    assert_not user.valid?

    user.crisis_contact_phone = "116 123"
    assert user.valid?
  end

  test "avatar must be an image under 5 MB" do
    user = users(:one)
    user.avatar.attach(io: file_fixture("notes.txt").open, filename: "notes.txt", content_type: "text/plain")
    assert_not user.valid?
    assert_includes user.errors[:avatar], "must be a PNG, JPEG or WebP image"

    user.avatar.attach(io: file_fixture("avatar.png").open, filename: "avatar.png", content_type: "image/png")
    assert user.valid?
  end

  test "remove_avatar purges the photo on save" do
    user = users(:one)
    user.avatar.attach(io: file_fixture("avatar.png").open, filename: "avatar.png", content_type: "image/png")
    assert user.avatar.attached?

    perform_enqueued_jobs { user.update!(remove_avatar: "1") }
    assert_not user.reload.avatar.attached?
  end
end
