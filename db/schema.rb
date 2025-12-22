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

<<<<<<< Updated upstream
ActiveRecord::Schema[8.1].define(version: 2025_12_21_000003) do
=======
ActiveRecord::Schema[8.1].define(version: 2025_12_22_140038) do
>>>>>>> Stashed changes
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "developers", force: :cascade do |t|
    t.string "country"
    t.datetime "created_at", null: false
    t.integer "founded_year"
    t.string "name"
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_developers_on_name", unique: true
  end

  create_table "game_developers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "developer_id"
    t.bigint "game_id"
    t.datetime "updated_at", null: false
    t.index ["developer_id"], name: "index_game_developers_on_developer_id"
    t.index ["game_id", "developer_id"], name: "index_game_developers_on_game_id_and_developer_id", unique: true
    t.index ["game_id"], name: "index_game_developers_on_game_id"
  end

  create_table "games", force: :cascade do |t|
    t.string "cover_url"
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "metacritic_score"
    t.date "release_date"
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["title"], name: "index_games_on_title", unique: true
  end

  create_table "profiles", force: :cascade do |t|
    t.text "bio"
    t.datetime "created_at", null: false
    t.boolean "private"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_profiles_on_user_id"
  end

<<<<<<< Updated upstream
=======
  create_table "ratings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "game_id", null: false
    t.integer "score", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["game_id"], name: "index_ratings_on_game_id"
    t.index ["user_id", "game_id"], name: "index_ratings_on_user_id_and_game_id", unique: true
    t.index ["user_id"], name: "index_ratings_on_user_id"
  end

  create_table "reviews", force: :cascade do |t|
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.bigint "game_id", null: false
    t.integer "rating", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["game_id"], name: "index_reviews_on_game_id"
    t.index ["user_id", "created_at"], name: "index_reviews_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_reviews_on_user_id"
  end

>>>>>>> Stashed changes
  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "game_developers", "developers"
  add_foreign_key "game_developers", "games"
  add_foreign_key "profiles", "users"
<<<<<<< Updated upstream
=======
  add_foreign_key "ratings", "games"
  add_foreign_key "ratings", "users"
  add_foreign_key "reviews", "games"
  add_foreign_key "reviews", "users"
  add_foreign_key "wishlists", "games"
  add_foreign_key "wishlists", "users"
>>>>>>> Stashed changes
end
