require "test_helper"

class SampleInsightsTest < ActiveSupport::TestCase
  setup do
    Distortion.create!(title: "Mental filter", description: "Dwelling on one negative detail.")
  end

  test "builds example entries without saving anything" do
    assert_no_difference [ "Situation.count", "SituationDistortion.count" ] do
      assert_equal 40, SampleInsights.new.total
    end
  end

  test "is deterministic for a given seed" do
    dates = ->(seed) { SampleInsights.new(seed:).situations.map { [ it.date, it.location, it.distortion_ids ] } }
    assert_equal dates.(7), dates.(7)
  end

  test "keeps every entry inside the 90 day range" do
    since = 90.days.ago
    assert SampleInsights.new.situations.all? { it.date >= since && it.date <= Time.current }
  end

  test "focuses on mind reading with real findings" do
    insights = SampleInsights.new
    assert_equal "Mind reading", insights.distortion.title
    assert insights.standout_cell
    assert_includes insights.standout_groups(:location), "Office"
    assert_equal "Mental filter", insights.pairs.first.distortions.last.title
  end
end
