class CreateSituationDistortions < ActiveRecord::Migration[8.1]
  def up
    create_table :situation_distortions do |t|
      t.references :situation, null: false, foreign_key: true
      t.references :distortion, null: false, foreign_key: true

      t.timestamps
    end
    add_index :situation_distortions, [ :situation_id, :distortion_id ], unique: true

    execute <<~SQL
      INSERT INTO situation_distortions (situation_id, distortion_id, created_at, updated_at)
      SELECT id, distortion_id, NOW(), NOW() FROM situations WHERE distortion_id IS NOT NULL
    SQL

    remove_reference :situations, :distortion, foreign_key: true
  end

  def down
    add_reference :situations, :distortion, foreign_key: true

    execute <<~SQL
      UPDATE situations SET distortion_id = (
        SELECT MIN(distortion_id) FROM situation_distortions WHERE situation_distortions.situation_id = situations.id
      )
    SQL

    drop_table :situation_distortions
  end
end
