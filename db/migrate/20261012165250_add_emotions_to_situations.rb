class AddEmotionsToSituations < ActiveRecord::Migration[8.1]
  def change
    add_column :situations, :emotions, :string, array: true, default: [], null: false
    add_column :situations, :emotion_level_after, :integer
    add_check_constraint :situations, "emotion_level_after >= 0 AND emotion_level_after <= 10", name: "emotion_level_after_range"
  end
end
