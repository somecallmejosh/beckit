module SituationsHelper
  STEP_TITLES = { "whats-on-your-mind" => "What's on your mind", "what-happened" => "What happened",
    "name-the-pattern" => "Name the pattern", "weigh-it-up" => "Weigh it up" }.freeze

  # The line under each step's heading.
  STEP_INTROS = { "whats-on-your-mind" => "Take a breath. There's no right or wrong way to fill this in.",
    "what-happened" => "Think back to the moment it started. A few details are enough.",
    "name-the-pattern" => "Look at the thought again. Does it fall into a familiar thinking trap?",
    "weigh-it-up" => "Set the thought beside the facts, then find a fairer way to say it." }.freeze

  # Heading and nav label for one page of the entry form (Situation::STEPS).
  def step_title(step) = STEP_TITLES.fetch(step)
  def step_intro(step) = STEP_INTROS.fetch(step)

  # Drawing that stands on the rule under a step's heading. All four share one square canvas with the
  # figure's feet at the bottom, so they line up from step to step; each recolours itself for dark mode.
  def step_image(step, **options)
    image_tag "steps/#{step}.svg", alt: "", width: 1000, height: 1000, decoding: "async", **options
  end

  # The sentence under a filtered journal's heading, e.g. "7 entries with this thinking trap, across your whole journal."
  def filter_summary(count, distortion:, query:)
    entries = pluralize(count, "entry")
    if distortion && query.present? then "#{entries} with #{distortion.title.downcase} #{count == 1 ? "matches" : "match"} “#{query}”."
    elsif distortion then "#{entries} with this thinking trap, across your whole journal."
    else "#{entries} #{count == 1 ? "matches" : "match"} “#{query}”."
    end
  end

  # Marks an entry in a list when a step still waits for its answer (Situation#next_step).
  def in_progress_badge(situation)
    tag.span("In progress", class: "badge-sky") if situation.next_step
  end

  # Placeholder for an empty field on an entry, muted so recorded answers stand out.
  def not_recorded(text = "Not recorded")
    tag.span(text, class: "font-normal text-stone-500 dark:text-stone-400")
  end

  # "Down 3 from 7", "Up 1 from 4" or "No change", when both ratings exist.
  def feeling_shift(situation)
    before, after = situation.emotion_level, situation.emotion_level_after
    return unless before && after

    change = after - before
    if change.zero? then "No change"
    else "#{change.negative? ? "Down" : "Up"} #{change.abs} from #{before}"
    end
  end
end
