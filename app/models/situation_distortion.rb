class SituationDistortion < ApplicationRecord
  belongs_to :situation
  belongs_to :distortion

  validates :distortion_id, uniqueness: { scope: :situation_id }
end
