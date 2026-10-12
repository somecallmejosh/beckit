module InsightsHelper
  RANGE_LABELS = { "30" => "30 days", "90" => "90 days", "365" => "Year", "all" => "All time" }.freeze
  WEEKDAY_LABELS = %w[ Sun Mon Tue Wed Thu Fri Sat ].freeze
  DAY_PART_LABELS = {
    morning: [ "Morning", "Morn", "5am-11am" ],
    midday: [ "Midday", "Mid", "11am-2pm" ],
    afternoon: [ "Afternoon", "Aft", "2pm-5pm" ],
    evening: [ "Evening", "Eve", "5pm-9pm" ],
    night: [ "Night", "Night", "9pm-5am" ]
  }.freeze

  # Sequential teal ramp for counts, empty first.
  HEAT_CLASSES = [
    "bg-stone-950/[0.03] text-stone-500 dark:bg-white/[0.03] dark:text-stone-400",
    "bg-teal-100 text-stone-900 dark:bg-teal-950 dark:text-teal-100",
    "bg-teal-200 text-stone-900 dark:bg-teal-900 dark:text-teal-50",
    "bg-teal-400 text-stone-950 dark:bg-teal-700 dark:text-white",
    "bg-teal-700 text-white dark:bg-teal-400 dark:text-stone-950"
  ].freeze

  # Diverging scale for lift: sky = less often than usual, amber = more often, gray = about usual.
  LIFT_CLASSES = {
    unknown: "bg-stone-950/[0.03] text-stone-500 dark:bg-white/[0.03] dark:text-stone-400",
    much_less: "bg-sky-200 text-stone-900 dark:bg-sky-800 dark:text-white",
    less: "bg-sky-50 text-stone-900 dark:bg-sky-950 dark:text-sky-100",
    usual: "bg-stone-100 text-stone-700 dark:bg-stone-800 dark:text-stone-200",
    more: "bg-amber-100 text-stone-900 dark:bg-amber-950 dark:text-amber-100",
    much_more: "bg-amber-300 text-stone-950 dark:bg-amber-600 dark:text-white"
  }.freeze

  def insights_link_params(insights, **overrides)
    { range: insights.range, distortion_id: insights.distortion&.id }.merge(overrides).compact
  end

  RANGE_PHRASES = { "30" => "in the last 30 days", "90" => "in the last 90 days", "365" => "in the last year", "all" => "so far" }.freeze

  # One item in the thinking-trap rail: a chip on small screens, a full-width row from lg up.
  # The selected state matches nav_link_to so the rail and the range tabs read as one control style.
  def rail_link(label, count, url, active:)
    classes = [
      "relative flex shrink-0 snap-start items-center justify-between gap-4 rounded-full px-3.5 py-1.5 text-base/6 ring-1 sm:text-sm/6",
      "lg:w-full lg:px-3 lg:py-2 lg:ring-0",
      if active
        "bg-stone-950/5 font-medium text-stone-900 ring-transparent dark:bg-white/10 dark:text-white"
      elsif count.zero?
        "text-stone-500 ring-stone-950/10 hover:bg-stone-950/5 hover:text-stone-700 dark:text-stone-400 dark:ring-white/10 dark:hover:bg-white/5"
      else
        "font-medium text-stone-700 ring-stone-950/10 hover:bg-stone-950/5 hover:text-stone-900 dark:text-stone-300 dark:ring-white/10 dark:hover:bg-white/5 dark:hover:text-white"
      end
    ]
    link_to url, class: classes, aria: { current: (active ? "page" : nil) } do
      safe_join([
        tag.span(label, class: "truncate"),
        tag.span(count, class: [ "tabular-nums", active ? "text-stone-700 dark:text-stone-200" : "text-stone-500 dark:text-stone-400" ])
      ])
    end
  end

  def range_phrase(range) = RANGE_PHRASES.fetch(range)

  # "In the 4 entries you re-rated, the feeling dropped by 2.5 points on average."
  def feeling_shift_sentence(shift)
    rated = "In the #{pluralize shift.entries, "entry"} you re-rated"
    change = number_with_precision(shift.average.abs, precision: 1, strip_insignificant_zeros: true)
    if shift.average.abs < 0.05 then "#{rated}, the feeling stayed about the same on average."
    else "#{rated}, the feeling #{shift.average.negative? ? "dropped" : "rose"} by #{change} #{"point".pluralize(shift.average.abs == 1 ? 1 : 2)} on average."
    end
  end

  # "Monday afternoons", or "around midday on Mondays".
  def when_phrase(wday, part)
    day = Date::DAYNAMES[wday]
    part == :midday ? "around midday on #{day}s" : "#{day} #{part}s"
  end

  def lift_short(lift)
    case lift_bucket(lift)
    when :unknown then "Too few entries"
    when :usual then "About usual"
    when :much_less, :less then "Less often"
    else "#{number_with_precision(lift, precision: 1)}× usual"
    end
  end

  def heat_class(value, max)
    level = value.zero? || max.zero? ? 0 : (value.fdiv(max) * 4).ceil.clamp(1, 4)
    HEAT_CLASSES[level]
  end

  def lift_class(lift)
    LIFT_CLASSES.fetch(lift_bucket(lift))
  end

  def lift_label(lift)
    case lift_bucket(lift)
    when :unknown then "too few entries to compare"
    when :usual then "about your usual rate"
    else "#{number_with_precision(lift, precision: 1)}× your usual rate"
    end
  end

  def percent(share)
    number_to_percentage(share * 100, precision: 0)
  end

  # Small trend line; scales to its container.
  def sparkline(values, label:)
    max = [ values.max.to_i, 1 ].max
    step = values.size > 1 ? 100.0 / (values.size - 1) : 0
    points = values.each_with_index.map { |value, i| "#{(i * step).round(2)},#{(22 - value.fdiv(max) * 20).round(2)}" }
    points = [ "0,#{points.first.split(",").last}", "100,#{points.first.split(",").last}" ] if values.size == 1

    tag.svg(viewBox: "0 0 100 24", preserveAspectRatio: "none", class: "h-6 w-24 overflow-visible text-teal-600 dark:text-teal-400", role: "img", aria: { label: }) do
      tag.polyline(points: points.join(" "), fill: "none", stroke: "currentColor", "stroke-width": 2, "stroke-linejoin": "round", "stroke-linecap": "round", "vector-effect": "non-scaling-stroke")
    end
  end

  private
    def lift_bucket(lift)
      if lift.nil? then :unknown
      elsif lift < 0.5 then :much_less
      elsif lift < 0.75 then :less
      elsif lift < DistortionInsights::STANDOUT_LIFT then :usual
      elsif lift < 2 then :more
      else :much_more
      end
    end
end
