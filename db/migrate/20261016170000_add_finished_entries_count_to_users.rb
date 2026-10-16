# How many entries each user has finished (every step answered). It only goes up, when an entry is finished,
# so the plant on the settings page never shrinks. Starts from the entries finished so far, trashed ones included.
class AddFinishedEntriesCountToUsers < ActiveRecord::Migration[8.1]
  def up
    add_column :users, :finished_entries_count, :integer, default: 0, null: false

    execute <<~SQL
      UPDATE users SET finished_entries_count = (
        SELECT COUNT(*) FROM situations
        WHERE situations.user_id = users.id
          AND TRIM(situations.thought_imagery) <> ''
          AND TRIM(situations.title) <> ''
          AND TRIM(situations.balanced_thought) <> ''
          AND EXISTS (SELECT 1 FROM situation_distortions WHERE situation_distortions.situation_id = situations.id)
      )
    SQL
  end

  def down
    remove_column :users, :finished_entries_count
  end
end
