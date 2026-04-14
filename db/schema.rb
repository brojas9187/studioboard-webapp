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

ActiveRecord::Schema[8.0].define(version: 2026_04_14_000200) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "memberships", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.bigint "user_id", null: false
    t.string "role", default: "member", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id", "user_id"], name: "index_memberships_on_organization_id_and_user_id", unique: true
    t.index ["organization_id"], name: "index_memberships_on_organization_id"
    t.index ["user_id"], name: "index_memberships_on_user_id"
  end

  create_table "organizations", force: :cascade do |t|
    t.string "name", null: false
    t.string "plan", default: "free", null: false
    t.string "stripe_customer_id"
    t.string "stripe_subscription_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["stripe_customer_id"], name: "index_organizations_on_stripe_customer_id"
    t.index ["stripe_subscription_id"], name: "index_organizations_on_stripe_subscription_id"
  end

  create_table "projects", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.bigint "creator_id", null: false
    t.string "name", null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["creator_id"], name: "index_projects_on_creator_id"
    t.index ["organization_id"], name: "index_projects_on_organization_id"
  end

  create_table "tasks", force: :cascade do |t|
    t.bigint "project_id", null: false
    t.bigint "creator_id", null: false
    t.bigint "assignee_id", null: false
    t.string "title", null: false
    t.text "description"
    t.boolean "completed", default: false, null: false
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assignee_id"], name: "index_tasks_on_assignee_id"
    t.index ["creator_id"], name: "index_tasks_on_creator_id"
    t.index ["project_id", "completed"], name: "index_tasks_on_project_id_and_completed"
    t.index ["project_id"], name: "index_tasks_on_project_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.string "password_salt", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "oauth_provider"
    t.string "oauth_uid"
    t.string "avatar_url"
    t.index "lower((email)::text)", name: "index_users_on_lower_email", unique: true
    t.index ["oauth_provider", "oauth_uid"], name: "index_users_on_oauth_provider_and_oauth_uid", unique: true
  end

  add_foreign_key "memberships", "organizations"
  add_foreign_key "memberships", "users"
  add_foreign_key "projects", "organizations"
  add_foreign_key "projects", "users", column: "creator_id"
  add_foreign_key "tasks", "projects"
  add_foreign_key "tasks", "users", column: "assignee_id"
  add_foreign_key "tasks", "users", column: "creator_id"
end
