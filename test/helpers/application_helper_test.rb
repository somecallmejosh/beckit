require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  setup do
    @user = User.new(name: "Joshua Briley", preferred_name: "Josh", date_of_birth: Date.new(1985, 6, 1))
  end

  test "greeting follows the time of day" do
    {
      9 => "Good morning, Josh",
      14 => "Good afternoon, Josh",
      19 => "Good evening, Josh",
      23 => "Hello, Josh",
      3 => "Hello, Josh"
    }.each do |hour, greeting|
      assert_equal greeting, greeting_for(@user, Time.zone.local(2026, 10, 7, hour))
    end
  end

  test "greeting image follows the time of day, with evening late at night" do
    { 9 => "morning", 14 => "afternoon", 19 => "evening", 23 => "evening", 3 => "evening" }.each do |hour, part|
      assert_match %r{greetings/#{part}[-.]}, greeting_image(Time.zone.local(2026, 10, 7, hour))
    end
  end

  test "greeting wishes a happy birthday" do
    assert_equal "Happy birthday, Josh", greeting_for(@user, Time.zone.local(2026, 6, 1, 9))
  end

  test "every kind word has its own drawing and copy" do
    assert_equal 10, KIND_WORDS.map { |words| words[:image] }.uniq.size
    KIND_WORDS.each do |words|
      assert Rails.root.join("app/assets/images/be-kind/#{words[:image]}.svg").exist?, words[:image]
      assert words.values_at(:heading, :body, :alt).all?(&:present?), words[:image]
    end
  end
end
