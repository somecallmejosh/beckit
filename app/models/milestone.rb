# One stage of the plant on the settings page, reached at a number of finished entries (User#finished_entries_count,
# which only goes up, so a stage stays reached). `becoming` finishes "N more until it's ..."; `announcement` is the
# notice when an entry reaches the stage.
class Milestone < Data.define(:slug, :name, :entries, :becoming, :announcement)
  ALL = [
    new("seed", "Seed", 10, "planted", "You planted a seed."),
    new("sprout", "Sprout", 20, "a sprout", "Your plant has sprouted."),
    new("seedling", "Seedling", 30, "a seedling", "Your plant is a seedling now."),
    new("young-plant", "Young plant", 40, "a young plant", "Your plant has grown into a young plant."),
    new("in-bloom", "In bloom", 50, "in bloom", "Your plant is in bloom."),
    new("small-tree", "Small tree", 60, "a small tree", "Your plant has grown into a small tree.")
  ].freeze

  def self.all = ALL
  def self.find(slug) = ALL.find { it.slug == slug }

  # The stage whose threshold is exactly this many finished entries. The count goes up one at a time,
  # so this is the stage an entry just reached, if any.
  def self.reached_at(finished) = ALL.find { it.entries == finished }

  def earned_by?(finished) = finished >= entries
end
