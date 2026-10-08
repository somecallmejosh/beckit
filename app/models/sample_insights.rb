# Example insights for the landing page: about 40 unsaved entries from a fixed seed, run
# through the real DistortionInsights code. Mind reading is skewed toward weekday afternoons
# at the office with a manager, often alongside mental filter, so the findings have something to say.
class SampleInsights < DistortionInsights
  FOCUS = "Mind reading"
  COMPANION = "Mental filter"
  PLACES = [ "Home", "Car", "Grocery store", "Office" ].freeze
  PEOPLE = [ "Just me", "My partner", "A friend", "My manager" ].freeze

  def initialize(seed: 7)
    @seed = seed
    super(nil, range: "90", distortion: Distortion.find_by(title: FOCUS))
  end

  def situations
    @situations ||= build_situations.sort_by(&:date)
  end

  private
    def build_situations
      rng = Random.new(@seed)
      distortions = Distortion.all.index_by(&:title)
      focus, companion = distortions[FOCUS], distortions[COMPANION]
      others = distortions.values - [ focus, companion ].compact

      focused = 13.times.map do
        tags = [ focus ]
        tags << companion if companion && rng.rand < 0.6
        tags << others.sample(random: rng) if rng.rand < 0.35
        entry(rng, days_ago: rng.rand(1..80), weekday: rng.rand(1..3), hour: rng.rand(14..16),
              place: rng.rand < 0.7 ? "Office" : PLACES.sample(random: rng),
              person: rng.rand < 0.7 ? "My manager" : PEOPLE.sample(random: rng), tags:)
      end

      rest = 27.times.map do
        entry(rng, days_ago: rng.rand(1..88), hour: rng.rand(7..21),
              place: PLACES.sample(random: rng), person: PEOPLE.sample(random: rng),
              tags: others.sample(rng.rand(1..2), random: rng))
      end

      focused + rest
    end

    # weekday: when given, moves the date to the nearest earlier Monday-Wednesday slot.
    def entry(rng, days_ago:, hour:, place:, person:, tags:, weekday: nil)
      day = Date.current - days_ago
      day -= (day.wday - weekday) % 7 if weekday
      Situation.new(
        title: "Example entry",
        date: Time.zone.local(day.year, day.month, day.day, hour, [ 0, 15, 30, 45 ].sample(random: rng)),
        location: place,
        who_was_involved: person,
        emotion_level: rng.rand(3..9),
        distortions: tags.compact
      )
    end
end
