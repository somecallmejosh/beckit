class Situation < ApplicationRecord
  EMOTIONS = %w[ Anxious Sad Angry Ashamed Guilty Frustrated Hurt Lonely Overwhelmed Hopeless ].freeze
  RESTORE_WINDOW = 30.days
  SEARCHABLE = %w[ title thought_imagery location who_was_involved evidence_for evidence_against balanced_thought ].freeze

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

  normalizes :location, :who_was_involved, with: ->(value) { value.squish.presence }
  normalizes :emotions, with: ->(list) { list.compact_blank.uniq }

  before_validation :default_title

  validates :title, :date, presence: true
  validates :emotion_level, :emotion_level_after, numericality: { only_integer: true, in: 0..10 }, allow_nil: true
  validate { errors.add(:emotions, "include one we don't recognize") unless (emotions - EMOTIONS).empty? }

  def trash! = update!(deleted_at: Time.current)
  def restore! = update!(deleted_at: nil)

  CSV_HEADERS = [ "Date", "Title", "Where", "Who was involved", "What went through your mind", "Feelings", "Feeling (0-10)",
    "Thinking traps", "Evidence for", "Evidence against", "Balanced thought", "Feeling after (0-10)" ].freeze

  # Times are in the current time zone (the user's, inside a request).
  def self.to_csv
    CSV.generate do |csv|
      csv << CSV_HEADERS
      all.each do |situation|
        csv << [ situation.date.strftime("%Y-%m-%d %H:%M"), situation.title, situation.location, situation.who_was_involved,
          situation.thought_imagery, situation.emotions.join("; "), situation.emotion_level, situation.distortions.map(&:title).sort.join("; "),
          situation.evidence_for, situation.evidence_against, situation.balanced_thought, situation.emotion_level_after ].map { spreadsheet_safe(it) }
      end
    end
  end

  # Spreadsheet apps run cells that start with these characters as formulas.
  def self.spreadsheet_safe(value)
    value.is_a?(String) && value.start_with?("=", "+", "-", "@", "\t", "\r") ? "'#{value}" : value
  end
  private_class_method :spreadsheet_safe

  private
    # The title is optional in the form: use the start of the thought, or the date.
    def default_title
      return if title.present?

      self.title = if thought_imagery.present?
        thought_imagery.squish.truncate_words(6).truncate(60)
      elsif date
        "Entry on #{I18n.l(date, format: :entry_date)}"
      else
        "Untitled entry"
      end
    end
end
