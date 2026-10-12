# Permanently removes entries deleted more than Situation::RESTORE_WINDOW ago. Scheduled daily in config/recurring.yml.
class PurgeDeletedSituationsJob < ApplicationJob
  queue_as :default

  def perform
    Situation.due_for_purge.find_each(&:destroy!)
  end
end
