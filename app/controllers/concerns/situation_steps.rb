# Shared by the first step (SituationsController#new/create) and the rest (Situations::StepsController).
module SituationSteps
  WHO_PRESETS = %w[ Self Colleague Spouse Daughter Son Parent Friend ].freeze

  private
    # Next and the nav's later steps save first and name a step in go_to; Save entry doesn't, and opens the entry.
    # The save that finishes an entry gets the balloon (shared/_balloon), or, when that finished entry reaches the
    # plant's next stage, the stage's own moment instead (shared/_stage_up).
    def redirect_after_step(situation)
      stage = Milestone.reached_at(situation.user.finished_entries_count) if situation.just_completed?
      if stage
        flash[:grown] = stage.slug
      elsif situation.just_completed?
        flash[:celebrate] = true
      end

      if params[:go_to].in?(Situation::STEPS)
        redirect_to situation_step_path(situation, params[:go_to]), status: :see_other
      else
        notice = if stage then "Entry complete. #{stage.announcement}"
        elsif situation.just_completed? then "Entry complete."
        else "Entry saved."
        end
        redirect_to situation, notice:, status: :see_other
      end
    end

    # The user's most-used thinking traps first, then alphabetical.
    def set_distortions
      usage = Current.user.situations.joins(:situation_distortions).group("situation_distortions.distortion_id").count
      @distortions = Distortion.order(:title).sort_by { [ -usage.fetch(it.id, 0), it.title ] }
      @distortions_used = usage.any?
    end

    # Past answers offered alphabetically in the combobox under each field; differently cased duplicates appear once.
    def set_suggestions
      @location_options = alphabetical(past_values(:location))
      @who_options = alphabetical(WHO_PRESETS + past_values(:who_was_involved))
    end

    def past_values(column)
      Current.user.situations.where.not(column => nil).distinct.pluck(column)
    end

    def alphabetical(values)
      values.uniq(&:downcase).sort_by(&:downcase)
    end

    # Each step only sends its own fields, so the rest are left as they are. user_id is set from Current.user.
    def situation_params
      params.expect(situation: [ :title, :date, :location, :distortion_id, :who_was_involved, :thought_imagery, :emotion_level, :emotion_level_after,
        :evidence_for, :evidence_against, :balanced_thought, distortion_ids: [], emotions: [] ])
    end
end
