class Situation < ApplicationRecord
  belongs_to :user
  has_many :situation_distortions, dependent: :destroy
  has_many :distortions, through: :situation_distortions

  normalizes :location, :who_was_involved, with: ->(value) { value.squish.presence }

  validates :title, :date, presence: true
  validates :emotion_level, numericality: { only_integer: true, in: 0..10 }, allow_nil: true

  CSV_HEADERS = [ "Date", "Title", "Where", "Who was involved", "What went through your mind", "Feeling (0-10)",
    "Thinking traps", "Evidence for", "Evidence against", "Balanced thought" ].freeze

  # Times are in the current time zone (the user's, inside a request).
  def self.to_csv
    CSV.generate do |csv|
      csv << CSV_HEADERS
      all.each do |situation|
        csv << [ situation.date.strftime("%Y-%m-%d %H:%M"), situation.title, situation.location, situation.who_was_involved,
          situation.thought_imagery, situation.emotion_level, situation.distortions.map(&:title).sort.join("; "),
          situation.evidence_for, situation.evidence_against, situation.balanced_thought ].map { spreadsheet_safe(it) }
      end
    end
  end

  # Spreadsheet apps run cells that start with these characters as formulas.
  def self.spreadsheet_safe(value)
    value.is_a?(String) && value.start_with?("=", "+", "-", "@", "\t", "\r") ? "'#{value}" : value
  end
  private_class_method :spreadsheet_safe
end
