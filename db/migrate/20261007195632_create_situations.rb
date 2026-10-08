class CreateSituations < ActiveRecord::Migration[8.1]
  def change
    create_table :situations do |t|
      t.string :title, null: false
      t.datetime :date, null: false
      t.string :location
      t.references :distortion, foreign_key: true
      t.string :who_was_involved
      t.string :thought_imagery
      t.integer :emotion_level
      t.text :evidence_for
      t.text :evidence_against
      t.text :balanced_thought
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
    add_index :situations, [ :user_id, :date ]
    add_check_constraint :situations, "emotion_level BETWEEN 0 AND 10", name: "emotion_level_range"
  end
end
