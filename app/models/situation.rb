class Situation < ApplicationRecord
  EMOTIONS = %w[ Anxious Sad Angry Ashamed Guilty Frustrated Hurt Lonely Overwhelmed Hopeless ].freeze
  RESTORE_WINDOW = 30.days
  # The entry form's pages, in order, each with the answers it needs before it saves. The first creates the entry.
  REQUIRED_ANSWERS = { "whats-on-your-mind" => %i[ thought_imagery title ], "what-happened" => [],
    "name-the-pattern" => %i[ distortion_ids ], "weigh-it-up" => [], "move-forward" => %i[ balanced_thought ] }.freeze
  STEPS = REQUIRED_ANSWERS.keys.freeze
  SEARCHABLE = %w[ title thought_imagery location who_was_involved action_in_moment evidence_for evidence_against balanced_thought
    action_next_time ].freeze

  belongs_to :user
  has_many :situation_distortions, dependent: :destroy
  has_many :distortions, through: :situation_distortions

  scope :kept, -> { where(deleted_at: nil) }
  scope :deleted, -> { where.not(deleted_at: nil) }
  scope :due_for_purge, -> { deleted.where(deleted_at: ...RESTORE_WINDOW.ago) }
  scope :tagged_with, ->(distortion) { where(id: SituationDistortion.where(distortion:).select(:situation_id)) }
  scope :search, ->(query) {
    pattern = "%#{sanitize_sql_like(query)}%"
    where(SEARCHABLE.map { "situations.#{it} ILIKE :pattern" }.join(" OR "), pattern:)
  }

  normalizes :title, :location, :who_was_involved, with: ->(value) { value.squish.presence }
  normalizes :emotions, with: ->(list) { list.compact_blank.uniq }

  validates :date, presence: true
  REQUIRED_ANSWERS.each { |step, attributes| validates(*attributes, presence: true, on: step.underscore.to_sym) if attributes.any? }
  validates :emotion_level, :emotion_level_after, numericality: { only_integer: true, in: 0..10 }, allow_nil: true
  validate { errors.add(:emotions, "include one we don't recognize") unless (emotions - EMOTIONS).empty? }

  # Saves one page of the entry form, checking that page's question. Rolls back if it can't: assigning
  # distortion_ids to a saved entry writes the links straight away. The save that answers the last open
  # question adds one to the user's finished entries (see #just_completed?).
  def save_step(step, attributes)
    was_complete = complete?
    @just_completed = false
    transaction do
      assign_attributes(attributes)
      save(context: step.underscore.to_sym) || raise(ActiveRecord::Rollback)
      if complete? && !was_complete
        user.increment!(:finished_entries_count)
        @just_completed = true
      end
      true
    end || false
  end

  # Whether the last #save_step finished this entry.
  def just_completed? = @just_completed.present?

  def answered?(step) = REQUIRED_ANSWERS.fetch(step).all? { public_send(it).present? }

  # The first step still waiting for its answer, or nil once every step has one.
  def next_step = STEPS.find { !answered?(it) }
  def complete? = next_step.nil?

  # Steps open in order: any up to the first one still waiting for its answer.
  def reachable?(step) = complete? || STEPS.index(step) <= STEPS.index(next_step)

  # The short name, or for older entries saved without one, the start of the thought or the date.
  def display_title
    title.presence || thought_imagery.to_s.squish.truncate_words(6).truncate(60).presence || "Entry on #{I18n.l(date, format: :entry_date)}"
  end

  def trash! = update!(deleted_at: Time.current)
  def restore! = update!(deleted_at: nil)

  CSV_HEADERS = [ "Date", "Title", "Where", "Who was involved", "What went through your mind", "Feelings", "Feeling (0-10)",
    "What you did", "Thinking traps", "Evidence for", "Evidence against", "Balanced thought", "Feeling after (0-10)", "Next time" ].freeze

  # Times are in the current time zone (the user's, inside a request).
  def self.to_csv
    CSV.generate do |csv|
      csv << CSV_HEADERS
      all.each do |situation|
        csv << [ situation.date.strftime("%Y-%m-%d %H:%M"), situation.title, situation.location, situation.who_was_involved,
          situation.thought_imagery, situation.emotions.join("; "), situation.emotion_level, situation.action_in_moment,
          situation.distortions.map(&:title).sort.join("; "), situation.evidence_for, situation.evidence_against, situation.balanced_thought,
          situation.emotion_level_after, situation.action_next_time ].map { spreadsheet_safe(it) }
      end
    end
  end

  # Spreadsheet apps run cells that start with these characters as formulas.
  def self.spreadsheet_safe(value)
    value.is_a?(String) && value.start_with?("=", "+", "-", "@", "\t", "\r") ? "'#{value}" : value
  end
  private_class_method :spreadsheet_safe
end
