class CreateDistortions < ActiveRecord::Migration[8.1]
  def change
    create_table :distortions do |t|
      t.string :title, null: false
      t.text :description, null: false

      t.timestamps
    end
    add_index :distortions, :title, unique: true
  end
end
