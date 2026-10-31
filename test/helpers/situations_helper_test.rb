require "test_helper"

class SituationsHelperTest < ActionView::TestCase
  test "feelings read back as a sentence, whichever were given" do
    situation = Situation.new(emotions: %w[ Anxious Ashamed ], emotion_level: 8)
    assert_equal "You felt anxious and ashamed, 8 out of 10.", feelings_sentence(situation)

    situation.emotion_level = nil
    assert_equal "You felt anxious and ashamed.", feelings_sentence(situation)

    situation.assign_attributes(emotions: [], emotion_level: 9)
    assert_equal "The feeling was 9 out of 10.", feelings_sentence(situation)

    situation.emotion_level = nil
    assert_nil feelings_sentence(situation)
  end
end
