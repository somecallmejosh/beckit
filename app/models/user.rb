class User < ApplicationRecord
  AVATAR_TYPES = %w[ image/png image/jpeg image/webp ].freeze
  AVATAR_MAX_SIZE = 5.megabytes
  PASSWORD_MIN_LENGTH = 8

  has_secure_password
  has_many :sessions, dependent: :destroy
  # Deleted entries stay restorable for a while (see Situation::RESTORE_WINDOW); `situations` hides them.
  has_many :all_situations, class_name: "Situation", dependent: :destroy
  has_many :situations, -> { kept }
  has_one_attached :avatar do |attachable|
    attachable.variant :thumb, resize_to_fill: [ 64, 64 ]
    attachable.variant :profile, resize_to_fill: [ 256, 256 ]
  end

  # Settings sends "1" to drop the current avatar.
  attr_accessor :remove_avatar

  normalizes :email_address, with: ->(e) { e.strip.downcase }
  normalizes :name, :preferred_name, :crisis_contact_name, :crisis_contact_phone, with: ->(value) { value.squish.presence }

  validates :name, presence: true
  validates :password, length: { minimum: PASSWORD_MIN_LENGTH }, allow_nil: true
  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :time_zone, inclusion: { in: ActiveSupport::TimeZone.all.map { it.tzinfo.name } }
  validates :date_of_birth, comparison: { greater_than_or_equal_to: Date.new(1900), less_than_or_equal_to: -> { Date.current } }, allow_nil: true
  validates :crisis_contact_phone, format: { with: /\A[\d\s()+.\-]{3,20}\z/ }, allow_nil: true
  validate :crisis_contact_complete
  validate :avatar_acceptable

  after_save { avatar.purge_later if remove_avatar == "1" && avatar.attached? }

  def first_name
    preferred_name.presence || name.to_s.split.first
  end

  # Every Rails name for the zone, e.g. "Edinburgh, London" for Europe/London.
  def time_zone_name
    ActiveSupport::TimeZone.all.select { it.tzinfo.name == time_zone }.map(&:name).join(", ").presence || time_zone
  end

  def us_time_zone?
    ActiveSupport::TimeZone.us_zones.any? { it.tzinfo.name == time_zone }
  end

  def initials
    name.to_s.split.values_at(0, -1).compact.uniq.map { it[0] }.join.upcase
  end

  # A Feb 29 birthday is celebrated on Feb 28 in other years.
  def birthday_today?(today = Date.current)
    return false unless date_of_birth

    month, day = date_of_birth.month, date_of_birth.day
    day = 28 if month == 2 && day == 29 && !today.leap?
    today.month == month && today.day == day
  end

  private
    def crisis_contact_complete
      return if crisis_contact_name.present? == crisis_contact_phone.present?

      errors.add(crisis_contact_name.present? ? :crisis_contact_phone : :crisis_contact_name, "is needed for your crisis contact")
    end

    def avatar_acceptable
      return unless avatar.attached? && attachment_changes["avatar"]

      errors.add(:avatar, "must be a PNG, JPEG or WebP image") unless avatar.blob.content_type.in?(AVATAR_TYPES)
      errors.add(:avatar, "must be smaller than 5 MB") if avatar.blob.byte_size > AVATAR_MAX_SIZE
    end
end
