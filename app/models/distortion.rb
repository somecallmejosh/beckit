class Distortion < ApplicationRecord
  has_many :situation_distortions, dependent: :destroy
  has_many :situations, through: :situation_distortions

  validates :title, presence: true, uniqueness: { case_sensitive: false }
  validates :description, presence: true
end
