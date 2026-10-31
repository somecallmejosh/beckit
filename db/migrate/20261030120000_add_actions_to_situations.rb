# What the user did in the moment, and what they could do in moments like it in the future. Both optional.
class AddActionsToSituations < ActiveRecord::Migration[8.1]
  def change
    add_column :situations, :action_in_moment, :text
    add_column :situations, :action_next_time, :text
  end
end
