module SituationsHelper
  # The sentence under a filtered journal's heading, e.g. "7 entries with this thinking trap, across your whole journal."
  def filter_summary(count, distortion:, query:)
    entries = pluralize(count, "entry")
    if distortion && query.present? then "#{entries} with #{distortion.title.downcase} #{count == 1 ? "matches" : "match"} “#{query}”."
    elsif distortion then "#{entries} with this thinking trap, across your whole journal."
    else "#{entries} #{count == 1 ? "matches" : "match"} “#{query}”."
    end
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
