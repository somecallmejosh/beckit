class AddDeletedAtToSituations < ActiveRecord::Migration[8.1]
  def change
    add_column :situations, :deleted_at, :datetime
    add_index :situations, :deleted_at, where: "deleted_at IS NOT NULL"
  end
end
