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

  test "until it has a short name, an entry shows the start of the thought, then the date" do
    situation = users(:one).situations.create!(date: Time.zone.local(2026, 10, 3, 9), thought_imagery: "Everyone in the room could tell I had no idea what I was saying")
    assert_nil situation.title
    assert_equal "Everyone in the room could tell...", situation.display_title

    situation = users(:one).situations.create!(date: Time.zone.local(2026, 10, 3, 9))
    assert_equal "Entry on Oct 3, 2026", situation.display_title

    situation.update!(title: "  Stand-up  ")
    assert_equal "Stand-up", situation.display_title

    situation = users(:one).situations.build
    assert_not situation.valid?
    assert_equal [ "Date can't be blank" ], situation.errors.full_messages
  end

  test "each step of the form has its required answers" do
    situation = users(:one).situations.build(date: Time.current)
    assert_not situation.save_step("whats-on-your-mind", thought_imagery: " ", title: "Stand-up")
    assert_not situation.save_step("whats-on-your-mind", thought_imagery: "I froze", title: "")
    assert situation.save_step("whats-on-your-mind", thought_imagery: "I froze", title: "Stand-up")

    assert situation.save_step("what-happened", location: "")
    assert situation.save_step("weigh-it-up", evidence_for: "")

    situation.save_step("name-the-pattern", distortion_ids: [ distortions(:catastrophizing).id ])
    assert_not situation.save_step("name-the-pattern", distortion_ids: [ "" ])
    assert_equal [ distortions(:catastrophizing) ], situation.reload.distortions

    assert_not situation.save_step("move-forward", balanced_thought: "")
    assert situation.save_step("move-forward", balanced_thought: "One pause is normal")
  end

  test "the next step is the first without its answer, and steps past it are out of reach" do
    situation = users(:one).situations.build(date: Time.current)
    assert_equal "whats-on-your-mind", situation.next_step
    assert_not situation.reachable?("what-happened")

    situation.update!(thought_imagery: "I froze", balanced_thought: "It happens")
    assert_equal "whats-on-your-mind", situation.next_step

    situation.update!(title: "Stand-up")
    assert_equal "name-the-pattern", situation.next_step
    assert situation.reachable?("what-happened")
    assert_not situation.reachable?("weigh-it-up")

    assert_nil situations(:one).next_step
    assert situations(:one).reachable?("weigh-it-up")
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
