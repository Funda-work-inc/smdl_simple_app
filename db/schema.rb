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

ActiveRecord::Schema[7.2].define(version: 2025_12_26_231424) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "api_call_logs", force: :cascade do |t|
    t.string "api_type", null: false
    t.string "endpoint", null: false
    t.text "request_body"
    t.text "response_body"
    t.string "status", null: false
    t.bigint "simple_transaction_id"
    t.datetime "called_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["api_type"], name: "index_api_call_logs_on_api_type"
    t.index ["called_at"], name: "index_api_call_logs_on_called_at"
    t.index ["simple_transaction_id"], name: "index_api_call_logs_on_simple_transaction_id"
  end

  create_table "simple_transaction_items", force: :cascade do |t|
    t.bigint "simple_transaction_id", null: false
    t.string "item_name", limit: 255, null: false
    t.integer "item_count", null: false
    t.integer "item_price", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["simple_transaction_id"], name: "index_simple_transaction_items_on_simple_transaction_id"
  end

  create_table "simple_transactions", force: :cascade do |t|
    t.integer "amount", null: false
    t.datetime "registration_datetime", null: false
    t.string "status", default: "active", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["registration_datetime"], name: "index_simple_transactions_on_registration_datetime"
    t.index ["status"], name: "index_simple_transactions_on_status"
  end

  add_foreign_key "api_call_logs", "simple_transactions"
  add_foreign_key "simple_transaction_items", "simple_transactions"
end
