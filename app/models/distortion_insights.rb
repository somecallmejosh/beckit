# Aggregates a user's journal into the numbers behind the insights dashboard.
# Volumes are personal-sized, so everything is computed in Ruby from one query,
# bucketed in the current Time.zone.
class DistortionInsights
  RANGES = { "30" => 30.days, "90" => 90.days, "365" => 1.year, "all" => nil }.freeze
  DEFAULT_RANGE = "90"
  DAY_PARTS = %i[ morning midday afternoon evening night ].freeze
  WEEKDAYS = [ 1, 2, 3, 4, 5, 6, 0 ].freeze # Monday first, matches Date#wday
  DAY_STARTS_AT = 5 # Entries before 5am count as the previous day's night.
  MIN_ENTRIES = 3   # Fewer entries than this is too little to compare.
  TOP_GROUPS = 6
  TOP_COLUMNS = 5
  TOP_PAIRS = 8
  STANDOUT_LIFT = 1.33 # At or above this, a group counts as "more often than usual".

  Row = Data.define(:distortion, :count, :share, :avg_emotion, :weekly)
  Cell = Data.define(:entries, :matches, :lift)
  Group = Data.define(:label, :entries, :cells)
  Pair = Data.define(:distortions, :count, :share)

  attr_reader :range, :distortion

  def initialize(user, range: DEFAULT_RANGE, distortion: nil)
    @user = user
    @range = RANGES.key?(range) ? range : DEFAULT_RANGE
    @distortion = distortion
  end

  def situations
    @situations ||= begin
      scope = @user.situations.includes(:distortions).order(:date)
      since = RANGES[range]&.ago
      (since ? scope.where(date: since..) : scope).to_a
    end
  end

  def total = situations.size
  def empty? = situations.empty?

  # Every distortion, including ones never logged, most common first.
  def frequency
    @frequency ||= Distortion.order(:title).map { |distortion|
      matching = situations.select { tagged?(it, distortion) }
      levels = matching.filter_map(&:emotion_level)
      Row.new(
        distortion:,
        count: matching.size,
        share: total.zero? ? 0.0 : matching.size.fdiv(total),
        avg_emotion: levels.any? ? levels.sum.fdiv(levels.size) : nil,
        weekly: weeks.map { |week| matching.count { week_of(it) == week } }
      )
    }.sort_by { [ -it.count, it.distortion.title ] }
  end

  # Week start dates covering the range, oldest first.
  def weeks
    @weeks ||= begin
      first = (RANGES[range]&.ago || situations.first&.date || Time.current).to_date.beginning_of_week
      (first..Date.current.beginning_of_week).step(7).to_a
    end
  end

  def weekly_totals
    weeks.map { |week| situations.count { week_of(it) == week } }
  end

  def weekly_focus
    frequency.find { it.distortion == distortion }&.weekly
  end

  # { [wday, part] => Cell } for every weekday and part of the day.
  def heatmap
    @heatmap ||= begin
      buckets = situations.group_by { [ weekday_of(it), day_part_of(it) ] }
      WEEKDAYS.product(DAY_PARTS).to_h { |key| [ key, cell_for(buckets.fetch(key, [])) ] }
    end
  end

  def by_location = @by_location ||= groups_for(:location)
  def by_person = @by_person ||= groups_for(:who_was_involved)

  # Distortion columns for the where/who matrices: the focused one, then the most common.
  def columns
    ([ distortion ] + frequency.select { it.count.positive? }.map(&:distortion)).compact.uniq.first(TOP_COLUMNS)
  end

  # Distortions logged together in the same entry. With a focus, the distortions that
  # accompany it (share = of the focused entries); otherwise the most common pairs
  # (share = of all entries).
  def pairs
    @pairs ||= distortion ? companions : top_pairs
  end

  def overall_avg_emotion
    levels = situations.filter_map(&:emotion_level)
    levels.sum.fdiv(levels.size) if levels.any?
  end

  def focus_row
    frequency.find { it.distortion == distortion } if distortion
  end

  # The [wday, part] where the focused distortion stands out most, with its cell.
  def standout_cell
    return unless distortion

    heatmap.select { |_, cell| standout?(cell) && cell.matches >= 2 }.max_by { |_, cell| [ cell.lift, cell.matches ] }
  end

  # Labels of places or people where the focused distortion shows up more often than usual.
  def standout_groups(column)
    return [] unless distortion

    ranked_groups(column).select { it.label != "Other" && standout?(it.cells[distortion]) }.map(&:label)
  end

  # Where/who groups ordered by how strongly the focused distortion shows up there;
  # groups with too few entries come next, and the "Other" bucket always last.
  def ranked_groups(column)
    groups = column == :location ? by_location : by_person
    groups.sort_by do |group|
      lift = group.cells[distortion]&.lift
      [ group.label == "Other" ? 2 : (lift ? 0 : 1), -(lift || 0), -group.entries ]
    end
  end

  def recent_entries(limit = 5)
    situations.select { tagged?(it, distortion) }.last(limit).reverse
  end

  # Distortions with the highest average intensity, among those with enough entries.
  def strongest(limit = 3)
    frequency.select { it.count >= MIN_ENTRIES && it.avg_emotion }.max_by(limit, &:avg_emotion)
  end

  def day_part_of(situation)
    case situation.date.hour
    when 5...11 then :morning
    when 11...14 then :midday
    when 14...17 then :afternoon
    when 17...21 then :evening
    else :night
    end
  end

  def weekday_of(situation)
    (situation.date - DAY_STARTS_AT.hours).wday
  end

  private
    def top_pairs
      situations.flat_map { it.distortions.sort_by(&:title).combination(2).to_a }.tally
        .map { |pair, count| Pair.new(distortions: pair, count:, share: count.fdiv(total)) }
        .sort_by { [ -it.count, it.distortions.map(&:title) ] }
        .first(TOP_PAIRS)
    end

    def companions
      focused = situations.select { tagged?(it, distortion) }
      focused.flat_map { it.distortions.to_a - [ distortion ] }.tally
        .map { |other, count| Pair.new(distortions: [ distortion, other ], count:, share: count.fdiv(focused.size)) }
        .sort_by { [ -it.count, it.distortions.last.title ] }
    end

    def standout?(cell)
      cell&.lift && cell.lift >= STANDOUT_LIFT && cell.entries >= MIN_ENTRIES
    end

    def tagged?(situation, distortion)
      situation.distortion_ids.include?(distortion.id)
    end

    def week_of(situation)
      situation.date.to_date.beginning_of_week
    end

    def cell_for(group, focus = distortion)
      return Cell.new(entries: group.size, matches: group.size, lift: nil) unless focus

      matches = group.count { tagged?(it, focus) }
      Cell.new(entries: group.size, matches:, lift: lift(group.size, matches, focus))
    end

    # How much more (>1) or less (<1) often a distortion shows up in this group than overall.
    def lift(entries, matches, focus)
      baseline = frequency.find { it.distortion == focus }&.share.to_f
      return if entries < MIN_ENTRIES || baseline.zero?

      matches.fdiv(entries) / baseline
    end

    # Top groups by entry count plus "Other"; values are grouped case-insensitively
    # and labelled with their most common spelling.
    def groups_for(column)
      grouped = situations.select { it.public_send(column).present? }.group_by { it.public_send(column).downcase }
      ranked = grouped.values.sort_by { [ -it.size, it.first.public_send(column).downcase ] }

      top = ranked.first(TOP_GROUPS).map { |group| [ most_common(group, column), group ] }
      rest = ranked.drop(TOP_GROUPS).flatten
      top << [ "Other", rest ] if rest.any?

      top.map do |label, group|
        Group.new(label:, entries: group.size, cells: columns.to_h { [ it, cell_for(group, it) ] })
      end
    end

    def most_common(group, column)
      group.map { it.public_send(column) }.tally.max_by { |value, count| [ count, value ] }.first
    end
end
