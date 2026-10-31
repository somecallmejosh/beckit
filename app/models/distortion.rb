class Distortion < ApplicationRecord
  has_many :situation_distortions, dependent: :destroy
  has_many :situations, through: :situation_distortions

  # Image shown on the trap's page (unless it has an illustration), and the 1200x630 social card built from it (see OgCard).
  has_one_attached :image do |attachable|
    attachable.variant :page, resize_to_fill: [ 720, 900 ], format: :webp, saver: { quality: 80 }, preprocessed: true
  end
  has_one_attached :og_image

  has_rich_text :details

  IMAGE_TYPES = %w[ image/png image/jpeg image/webp ].freeze
  STARTER_PHOTOS = Rails.root.join("db/seeds/traps")
  ILLUSTRATIONS = Rails.root.glob("app/assets/images/traps/*.svg").map { "traps/#{it.basename}" }.to_set.freeze

  validates :title, presence: true, uniqueness: { case_sensitive: false }
  validates :description, presence: true
  validate :image_is_a_photo

  # The card shows the photo, title and description, so rebuild it when any of them change. Active Storage
  # clears its pending changes in its own after_commit, which runs first, so note a new photo on save.
  after_save { @card_outdated = attachment_changes.key?("image") || saved_change_to_title? || saved_change_to_description? }
  after_commit :refresh_og_image_later, on: %i[ create update ], if: -> { @card_outdated }

  normalizes :questions, with: ->(text) { text.lines.map(&:squish).compact_blank.join("\n").presence }

  def slug = title.parameterize

  # Questions that help test a thought caught in this trap, offered on the Weigh it up step.
  def question_list = questions.to_s.split("\n")

  # Attaches the trap's starter photo (db/seeds/traps/<slug>.webp) when it has none, or swaps in a newer
  # version when it still shows an older starter photo. A photo uploaded through the admin form is kept.
  def refresh_starter_photo
    path = STARTER_PHOTOS.join("#{slug}.webp")
    return unless path.exist?
    return if image.attached? && (image.filename != path.basename.to_s || image.checksum == Digest::MD5.file(path).base64digest)

    image.attach(io: path.open, filename: path.basename.to_s, content_type: "image/webp")
  end

  # The animated drawing (app/assets/images/traps/<slug>.svg) shown in place of the starter image, which is
  # its still copy for the social card. An image uploaded through the admin form is shown as is.
  def illustration
    path = "traps/#{slug}.svg"
    path if path.in?(ILLUSTRATIONS) && image.attached? && image.filename.to_s == "#{slug}.webp"
  end

  def refresh_og_image
    if image.attached?
      og_image.attach(io: StringIO.new(OgCard.new(self).to_png), filename: "#{slug}-og.png", content_type: "image/png")
    else
      og_image.purge
    end
  end

  private
    def refresh_og_image_later
      @card_outdated = false
      Distortion::RefreshOgImageJob.perform_later(self)
    end

    def image_is_a_photo
      return unless image.attached? && attachment_changes.key?("image")

      errors.add(:image, "must be a PNG, JPEG or WebP image") unless image.blob.content_type.in?(IMAGE_TYPES)
      errors.add(:image, "must be smaller than 10 MB") if image.blob.byte_size > 10.megabytes
    end
end
