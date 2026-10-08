require "test_helper"

class SituationTest < ActiveSupport::TestCase
  test "valid fixture" do
    assert situations(:one).valid?
  end

  test "requires title, date and user" do
    situation = Situation.new
    assert_not situation.valid?
    assert_includes situation.errors[:title], "can't be blank"
    assert_includes situation.errors[:date], "can't be blank"
    assert_includes situation.errors[:user], "must exist"
  end

  test "distortions are optional" do
    situation = users(:one).situations.build(title: "No distortion", date: Time.current)
    assert situation.valid?
  end

  test "emotion_level must be an integer from 0 to 10" do
    situation = situations(:one)

    [ 0, 10, nil ].each do |level|
      situation.emotion_level = level
      assert situation.valid?, "expected #{level.inspect} to be valid"
    end

    [ -1, 11 ].each do |level|
      situation.emotion_level = level
      assert_not situation.valid?, "expected #{level.inspect} to be invalid"
    end
  end
  test "can have many distortions" do
    assert_equal %w[ Catastrophizing Mind\ reading ], situations(:one).distortions.map(&:title).sort
  end

  test "cannot link the same distortion twice" do
    link = SituationDistortion.new(situation: situations(:one), distortion: distortions(:catastrophizing))
    assert_not link.valid?
  end

  test "squishes location and who_was_involved, and blanks become nil" do
    situation = Situation.new(location: "  Home   office ", who_was_involved: "   ")
    assert_equal "Home office", situation.location
    assert_nil situation.who_was_involved
  end
end
