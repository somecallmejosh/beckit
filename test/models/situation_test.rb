require "test_helper"

class SituationTest < ActiveSupport::TestCase
  test "valid fixture" do
    assert situations(:one).valid?
  end

  test "requires date and user; the title always gets a default" do
    situation = Situation.new
    assert_not situation.valid?
    assert_empty situation.errors[:title]
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

  test "title defaults to the start of the thought, then the date" do
    situation = users(:one).situations.create!(date: Time.zone.local(2026, 10, 3, 9), thought_imagery: "Everyone in the room could tell I had no idea what I was saying")
    assert_equal "Everyone in the room could tell...", situation.title

    situation = users(:one).situations.create!(date: Time.zone.local(2026, 10, 3, 9))
    assert_equal "Entry on Oct 3, 2026", situation.title

    situation = users(:one).situations.build
    assert_not situation.valid?
    assert_equal [ "Date can't be blank" ], situation.errors.full_messages
  end

  test "emotions are cleaned up and limited to the known list" do
    situation = users(:one).situations.build(date: Time.current, emotions: [ "Sad", "", "Sad", "Anxious" ])
    assert situation.valid?
    assert_equal %w[ Sad Anxious ], situation.emotions

    situation.emotions = [ "Bored" ]
    assert_not situation.valid?
    assert_includes situation.errors.full_messages, "Feelings include one we don't recognize"
  end

  test "feeling now is 0 to 10" do
    situation = situations(:one)
    situation.emotion_level_after = 11
    assert_not situation.valid?
  end

  test "search covers the written fields, case-insensitively, and treats wildcards literally" do
    assert_equal [ situations(:one) ], Situation.search("FIRED").to_a
    assert_equal [ situations(:one) ], Situation.search("reviews have").to_a
    assert_empty Situation.search("%")
  end

  test "trash and restore" do
    situation = situations(:one)
    situation.trash!
    assert_not_includes users(:one).situations, situation
    assert_includes users(:one).all_situations, situation

    situation.restore!
    assert_includes users(:one).situations, situation
  end
end
