# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_10_12_181634) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "action_text_rich_texts", force: :cascade do |t|
    t.string "name", null: false
    t.text "body"
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "distortions", force: :cascade do |t|
    t.string "title", null: false
    t.text "description", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["title"], name: "index_distortions_on_title", unique: true
  end

  create_table "sessions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "situation_distortions", force: :cascade do |t|
    t.bigint "situation_id", null: false
    t.bigint "distortion_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["distortion_id"], name: "index_situation_distortions_on_distortion_id"
    t.index ["situation_id", "distortion_id"], name: "index_situation_distortions_on_situation_id_and_distortion_id", unique: true
    t.index ["situation_id"], name: "index_situation_distortions_on_situation_id"
  end

  create_table "situations", force: :cascade do |t|
    t.string "title", null: false
    t.datetime "date", null: false
    t.string "location"
    t.string "who_was_involved"
    t.string "thought_imagery"
    t.integer "emotion_level"
    t.text "evidence_for"
    t.text "evidence_against"
    t.text "balanced_thought"
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.string "emotions", default: [], null: false, array: true
    t.integer "emotion_level_after"
    t.index ["deleted_at"], name: "index_situations_on_deleted_at", where: "(deleted_at IS NOT NULL)"
    t.index ["user_id", "date"], name: "index_situations_on_user_id_and_date"
    t.index ["user_id"], name: "index_situations_on_user_id"
    t.check_constraint "emotion_level >= 0 AND emotion_level <= 10", name: "emotion_level_range"
    t.check_constraint "emotion_level_after >= 0 AND emotion_level_after <= 10", name: "emotion_level_after_range"
  end

  create_table "users", force: :cascade do |t|
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name", null: false
    t.boolean "admin", default: false, null: false
    t.string "time_zone", default: "America/New_York", null: false
    t.string "preferred_name"
    t.date "date_of_birth"
    t.string "crisis_contact_name"
    t.string "crisis_contact_phone"
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "sessions", "users"
  add_foreign_key "situation_distortions", "distortions"
  add_foreign_key "situation_distortions", "situations"
  add_foreign_key "situations", "users"
end
