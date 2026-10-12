module SituationsHelper
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
