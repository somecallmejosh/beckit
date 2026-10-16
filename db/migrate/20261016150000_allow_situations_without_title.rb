# The short name is asked on the entry's second step, so an entry saved after the first has none yet.
class AllowSituationsWithoutTitle < ActiveRecord::Migration[8.1]
  def change
    change_column_null :situations, :title, true
  end
end
