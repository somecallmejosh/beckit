require "test_helper"

class DistortionInsightsTest < ActiveSupport::TestCase
  setup do
    @user = users(:admin)
    @catastrophizing = distortions(:catastrophizing)
    @mind_reading = distortions(:mind_reading)
    @original_zone = Time.zone
    Time.zone = "America/New_York"
    travel_to Time.zone.local(2026, 10, 7, 12)
  end

  teardown do
    Time.zone = @original_zone
  end

  def log(at, location: nil, who: nil, distortions: [], emotion_level: nil)
    @user.situations.create!(title: "Entry", date: at, location:, who_was_involved: who, distortions:, emotion_level:)
  end

  test "frequency includes every distortion, even unused ones, most common first" do
    log(1.day.ago, distortions: [ @mind_reading ], emotion_level: 4)
    log(2.days.ago, distortions: [ @mind_reading, @catastrophizing ], emotion_level: 8)
    log(3.days.ago)

    rows = DistortionInsights.new(@user).frequency
    assert_equal Distortion.count, rows.size
    assert_equal [ @mind_reading, @catastrophizing ], rows.map(&:distortion)
    assert_equal [ 2, 1 ], rows.map(&:count)
    assert_in_delta 2 / 3.0, rows.first.share
    assert_in_delta 6.0, rows.first.avg_emotion
  end

  test "unused distortions have a zero count" do
    log(1.day.ago, distortions: [ @mind_reading ])
    row = DistortionInsights.new(@user).frequency.find { it.distortion == @catastrophizing }
    assert_equal 0, row.count
    assert_nil row.avg_emotion
  end

  test "range limits entries and only the user's own entries count" do
    log(10.days.ago)
    log(60.days.ago)

    assert_equal 1, DistortionInsights.new(@user, range: "30").total
    assert_equal 2, DistortionInsights.new(@user, range: "90").total
    assert_equal 2, DistortionInsights.new(@user, range: "bogus").total
  end

  test "weekly counts cover the range and sum to the total" do
    log(1.day.ago)
    log(20.days.ago)
    insights = DistortionInsights.new(@user, range: "30")

    assert_equal 2, insights.weekly_totals.sum
    assert_equal Date.current.beginning_of_week, insights.weeks.last
  end

  test "late entries count toward the previous day's night in the user's time zone" do
    insights = DistortionInsights.new(@user)
    evening = Situation.new(date: Time.zone.local(2026, 10, 5, 23, 30)) # Monday
    after_midnight = Situation.new(date: Time.zone.local(2026, 10, 6, 1, 0)) # Tuesday, 1am
    morning = Situation.new(date: Time.zone.local(2026, 10, 6, 9, 0))

    assert_equal [ 1, :night ], [ insights.weekday_of(evening), insights.day_part_of(evening) ]
    assert_equal [ 1, :night ], [ insights.weekday_of(after_midnight), insights.day_part_of(after_midnight) ]
    assert_equal [ 2, :morning ], [ insights.weekday_of(morning), insights.day_part_of(morning) ]
  end

  test "heatmap buckets entries by weekday and part of day" do
    log(Time.zone.local(2026, 10, 6, 1, 0))
    log(Time.zone.local(2026, 10, 5, 22, 0))

    heatmap = DistortionInsights.new(@user).heatmap
    assert_equal 35, heatmap.size
    assert_equal 2, heatmap[[ 1, :night ]].entries
  end

  test "lift compares a group's rate with the overall rate" do
    3.times { log(1.day.ago, location: "Office", distortions: [ @mind_reading ]) }
    3.times { log(1.day.ago, location: "Home") }

    office = DistortionInsights.new(@user).by_location.find { it.label == "Office" }
    cell = office.cells[@mind_reading]
    assert_equal 3, cell.matches
    assert_in_delta 2.0, cell.lift
  end

  test "lift is nil when a group has too few entries" do
    2.times { log(1.day.ago, location: "Car", distortions: [ @mind_reading ]) }

    car = DistortionInsights.new(@user).by_location.first
    assert_nil car.cells[@mind_reading].lift
  end

  test "groups locations case-insensitively under the most common spelling" do
    log(1.day.ago, location: "Office")
    log(2.days.ago, location: "office")
    log(3.days.ago, location: "Office")

    groups = DistortionInsights.new(@user).by_location
    assert_equal [ [ "Office", 3 ] ], groups.map { [ it.label, it.entries ] }
  end

  test "folds groups beyond the top ones into Other" do
    8.times { |i| log(1.day.ago, who: "Person #{i}") }

    labels = DistortionInsights.new(@user).by_person.map(&:label)
    assert_equal DistortionInsights::TOP_GROUPS + 1, labels.size
    assert_equal "Other", labels.last
  end

  test "columns lead with the focused distortion" do
    log(1.day.ago, distortions: [ @mind_reading ])
    log(2.days.ago, distortions: [ @mind_reading ])

    assert_equal [ @mind_reading ], DistortionInsights.new(@user).columns
    assert_equal [ @catastrophizing, @mind_reading ], DistortionInsights.new(@user, distortion: @catastrophizing).columns
  end

  test "pairs lists distortions logged together, most common first" do
    labeling = Distortion.create!(title: "Labeling", description: "Global labels.")
    2.times { log(1.day.ago, distortions: [ @mind_reading, @catastrophizing ]) }
    log(2.days.ago, distortions: [ @mind_reading, labeling ])
    log(3.days.ago, distortions: [ @mind_reading ])

    pairs = DistortionInsights.new(@user).pairs
    assert_equal [ [ @catastrophizing, @mind_reading ], [ labeling, @mind_reading ] ], pairs.map(&:distortions)
    assert_equal [ 2, 1 ], pairs.map(&:count)
    assert_in_delta 0.5, pairs.first.share
  end

  test "with a focus, pairs are the focused distortion's companions" do
    labeling = Distortion.create!(title: "Labeling", description: "Global labels.")
    2.times { log(1.day.ago, distortions: [ @mind_reading, @catastrophizing ]) }
    log(2.days.ago, distortions: [ @mind_reading, labeling ])
    log(3.days.ago, distortions: [ @mind_reading ])
    log(4.days.ago, distortions: [ @catastrophizing, labeling ])

    pairs = DistortionInsights.new(@user, distortion: @mind_reading).pairs
    assert_equal [ @catastrophizing, labeling ], pairs.map { it.distortions.last }
    assert_in_delta 0.5, pairs.first.share
    assert_in_delta 0.25, pairs.last.share
  end

  test "overall_avg_emotion and focus_row" do
    log(1.day.ago, distortions: [ @mind_reading ], emotion_level: 8)
    log(2.days.ago, emotion_level: 4)

    insights = DistortionInsights.new(@user, distortion: @mind_reading)
    assert_in_delta 6.0, insights.overall_avg_emotion
    assert_equal 1, insights.focus_row.count
    assert_nil DistortionInsights.new(@user).focus_row
  end

  test "standout_cell needs lift, enough entries and two matches" do
    monday_afternoon = Time.zone.local(2026, 10, 5, 15)
    3.times { |i| log(monday_afternoon + i.minutes, distortions: (i < 2 ? [ @mind_reading ] : [])) }
    6.times { |i| log(Time.zone.local(2026, 10, 6, 9) + i.minutes) }

    key, cell = DistortionInsights.new(@user, distortion: @mind_reading).standout_cell
    assert_equal [ 1, :afternoon ], key
    assert_equal 2, cell.matches

    assert_nil DistortionInsights.new(@user, distortion: @catastrophizing).standout_cell
  end

  test "standout_groups lists groups well above the usual rate, never Other" do
    3.times { log(1.day.ago, location: "Office", distortions: [ @mind_reading ]) }
    3.times { log(1.day.ago, location: "Home") }

    insights = DistortionInsights.new(@user, distortion: @mind_reading)
    assert_equal [ "Office" ], insights.standout_groups(:location)
    assert_empty DistortionInsights.new(@user).standout_groups(:location)
  end

  test "ranked_groups orders by lift with too-few groups, then Other, last" do
    log(1.day.ago, location: "Car", distortions: [ @mind_reading ])
    3.times { log(1.day.ago, location: "Home") }
    3.times { log(1.day.ago, location: "Office", distortions: [ @mind_reading ]) }

    6.times { |i| log(1.day.ago, location: "Place #{i}", distortions: [ @mind_reading ]) }

    labels = DistortionInsights.new(@user, distortion: @mind_reading).ranked_groups(:location).map(&:label)
    assert_equal [ "Office", "Home" ], labels.first(2)
    assert_equal "Other", labels.last
    assert_includes labels[2..-2], "Car"
  end

  test "recent_entries are the focused distortion's newest entries" do
    old = log(3.days.ago, distortions: [ @mind_reading ])
    log(2.days.ago)
    recent = log(1.day.ago, distortions: [ @mind_reading ])

    assert_equal [ recent, old ], DistortionInsights.new(@user, distortion: @mind_reading).recent_entries
  end

  test "strongest skips distortions with too few entries" do
    3.times { log(1.day.ago, distortions: [ @mind_reading ], emotion_level: 5) }
    2.times { log(1.day.ago, distortions: [ @catastrophizing ], emotion_level: 10) }

    assert_equal [ @mind_reading ], DistortionInsights.new(@user).strongest.map(&:distortion)
  end
end
