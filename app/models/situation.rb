class Situation < ApplicationRecord
  belongs_to :user
  has_many :situation_distortions, dependent: :destroy
  has_many :distortions, through: :situation_distortions

  normalizes :location, :who_was_involved, with: ->(value) { value.squish.presence }

  validates :title, :date, presence: true
  validates :emotion_level, numericality: { only_integer: true, in: 0..10 }, allow_nil: true
end
