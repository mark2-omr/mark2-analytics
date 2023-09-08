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

ActiveRecord::Schema[7.0].define(version: 2023_01_16_012925) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "groups", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "results", force: :cascade do |t|
    t.integer "survey_id"
    t.integer "user_id"
    t.integer "grade"
    t.integer "subject"
    t.binary "file"
    t.json "parsed"
    t.json "converted"
    t.json "messages"
    t.boolean "verified"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["survey_id", "user_id"], name: "index_results_on_survey_id_and_user_id"
  end

  create_table "surveys", force: :cascade do |t|
    t.integer "group_id"
    t.string "name"
    t.binary "definition"
    t.string "convert_url"
    t.json "grades"
    t.json "subjects"
    t.json "questions"
    t.json "question_attributes"
    t.json "student_attributes"
    t.boolean "submittable", default: true
    t.json "aggregated"
    t.binary "merged"
    t.date "held_on"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["group_id"], name: "index_surveys_on_group_id"
  end

  create_table "users", force: :cascade do |t|
    t.integer "group_id"
    t.string "provider"
    t.string "uid"
    t.string "email"
    t.string "name"
    t.boolean "admin", default: false
    t.boolean "manager", default: false
    t.text "search_text"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["group_id"], name: "index_users_on_group_id"
    t.index ["provider", "uid"], name: "index_users_on_provider_and_uid", unique: true
  end

end
