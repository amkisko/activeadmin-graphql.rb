# frozen_string_literal: true

ActiveRecord::Schema.define(version: 20_250_330_000_001) do
  create_table "active_admin_comments", force: :cascade do |t|
    t.string "namespace"
    t.text "body"
    t.string "resource_type"
    t.bigint "resource_id"
    t.string "author_type"
    t.bigint "author_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author_type", "author_id"], name: "index_active_admin_comments_on_author"
    t.index ["namespace"], name: "index_active_admin_comments_on_namespace"
    t.index ["resource_type", "resource_id"], name: "index_active_admin_comments_on_resource"
  end

  create_table "admin_users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_admin_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_admin_users_on_reset_password_token", unique: true
  end

  create_table "library_editions", primary_key: ["book_code", "seq"], id: false, force: :cascade do |t|
    t.string "book_code", null: false
    t.integer "seq", null: false
    t.string "label"
  end

  create_table "posts", force: :cascade do |t|
    t.string "title"
    t.text "body"
    t.date "published_date"
    t.integer "author_id"
    t.integer "position"
    t.integer "custom_category_id"
    t.boolean "starred"
    t.integer "foo_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", force: :cascade do |t|
    t.string "type"
    t.string "first_name"
    t.string "last_name"
    t.string "username"
    t.integer "age"
    t.string "encrypted_password"
    t.string "reason_of_sign_in"
    t.integer "sign_in_count", default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end
end
