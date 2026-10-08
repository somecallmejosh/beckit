# Before users had a time zone, dates were entered as Eastern wall-clock times
# but stored as if they were UTC. Shift them so they mean what was typed.
class ReinterpretSituationDatesAsEastern < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      UPDATE situations SET date = (date AT TIME ZONE 'America/New_York') AT TIME ZONE 'UTC'
    SQL
  end

  def down
    execute <<~SQL
      UPDATE situations SET date = (date AT TIME ZONE 'UTC') AT TIME ZONE 'America/New_York'
    SQL
  end
end
