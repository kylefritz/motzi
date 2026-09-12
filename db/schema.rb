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

ActiveRecord::Schema[8.1].define(version: 2026_07_14_034616) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pg_stat_statements"

  create_table "active_admin_comments", force: :cascade do |t|
    t.bigint "author_id"
    t.string "author_type"
    t.text "body"
    t.datetime "created_at", null: false
    t.string "namespace"
    t.bigint "resource_id"
    t.string "resource_type"
    t.datetime "updated_at", null: false
    t.index [ "author_type", "author_id" ], name: "index_active_admin_comments_on_author_type_and_author_id"
    t.index [ "namespace" ], name: "index_active_admin_comments_on_namespace"
    t.index [ "resource_type", "resource_id" ], name: "index_active_admin_comments_on_resource_type_and_resource_id"
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index [ "blob_id" ], name: "index_active_storage_attachments_on_blob_id"
    t.index [ "record_type", "record_id", "name", "blob_id" ], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", precision: nil, null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index [ "key" ], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index [ "blob_id", "variation_digest" ], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "activity_events", force: :cascade do |t|
    t.string "action", null: false
    t.datetime "created_at", null: false
    t.string "description", null: false
    t.jsonb "metadata", default: {}
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.string "week_id", null: false
    t.index [ "action" ], name: "index_activity_events_on_action"
    t.index [ "user_id" ], name: "index_activity_events_on_user_id"
    t.index [ "week_id" ], name: "index_activity_events_on_week_id"
  end

  create_table "ahoy_events", force: :cascade do |t|
    t.string "name"
    t.jsonb "properties"
    t.datetime "time", precision: nil
    t.bigint "user_id"
    t.bigint "visit_id"
    t.index [ "name", "time" ], name: "index_ahoy_events_on_name_and_time"
    t.index [ "properties" ], name: "index_ahoy_events_on_properties", opclass: :jsonb_path_ops, using: :gin
    t.index [ "user_id" ], name: "index_ahoy_events_on_user_id"
    t.index [ "visit_id" ], name: "index_ahoy_events_on_visit_id"
  end

  create_table "ahoy_messages", force: :cascade do |t|
    t.datetime "clicked_at", precision: nil
    t.string "job_id"
    t.string "job_name"
    t.string "mailer"
    t.bigint "menu_id"
    t.datetime "opened_at", precision: nil
    t.bigint "order_id"
    t.bigint "pickup_day_id"
    t.datetime "sent_at", precision: nil
    t.text "subject"
    t.text "to"
    t.string "token"
    t.bigint "user_id"
    t.string "user_type"
    t.index [ "menu_id" ], name: "index_ahoy_messages_on_menu_id"
    t.index [ "order_id" ], name: "index_ahoy_messages_on_order_id"
    t.index [ "token" ], name: "index_ahoy_messages_on_token"
    t.index [ "user_type", "user_id" ], name: "index_ahoy_messages_on_user_type_and_user_id"
  end

  create_table "ahoy_visits", force: :cascade do |t|
    t.string "app_version"
    t.string "browser"
    t.string "city"
    t.string "country"
    t.string "device_type"
    t.string "ip"
    t.text "landing_page"
    t.float "latitude"
    t.float "longitude"
    t.string "os"
    t.string "os_version"
    t.string "platform"
    t.text "referrer"
    t.string "referring_domain"
    t.string "region"
    t.datetime "started_at", precision: nil
    t.text "user_agent"
    t.bigint "user_id"
    t.string "utm_campaign"
    t.string "utm_content"
    t.string "utm_medium"
    t.string "utm_source"
    t.string "utm_term"
    t.string "visit_token"
    t.string "visitor_token"
    t.index [ "user_id" ], name: "index_ahoy_visits_on_user_id"
    t.index [ "visit_token" ], name: "index_ahoy_visits_on_visit_token", unique: true
  end

  create_table "analysis_replies", force: :cascade do |t|
    t.bigint "anomaly_analysis_id", null: false
    t.string "author_email", null: false
    t.string "author_name"
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.string "message_id"
    t.integer "source", default: 0, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index [ "anomaly_analysis_id" ], name: "index_analysis_replies_on_anomaly_analysis_id"
    t.index [ "message_id" ], name: "index_analysis_replies_on_message_id", unique: true
    t.index [ "user_id" ], name: "index_analysis_replies_on_user_id"
  end

  create_table "anomaly_analyses", force: :cascade do |t|
    t.string "api_model"
    t.integer "cache_creation_input_tokens"
    t.integer "cache_read_input_tokens"
    t.integer "cost_cents"
    t.datetime "created_at", null: false
    t.integer "input_tokens"
    t.string "model_used"
    t.integer "output_tokens"
    t.string "overall_status"
    t.text "prompt_used"
    t.text "result", null: false
    t.string "stop_reason"
    t.string "trigger", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.string "week_id", null: false
    t.index [ "user_id" ], name: "index_anomaly_analyses_on_user_id"
    t.index [ "week_id" ], name: "index_anomaly_analyses_on_week_id"
  end

  create_table "blazer_audits", force: :cascade do |t|
    t.datetime "created_at", precision: nil
    t.string "data_source"
    t.bigint "query_id"
    t.text "statement"
    t.bigint "user_id"
    t.index [ "query_id" ], name: "index_blazer_audits_on_query_id"
    t.index [ "user_id" ], name: "index_blazer_audits_on_user_id"
  end

  create_table "blazer_checks", force: :cascade do |t|
    t.string "check_type"
    t.datetime "created_at", null: false
    t.bigint "creator_id"
    t.text "emails"
    t.datetime "last_run_at", precision: nil
    t.text "message"
    t.bigint "query_id"
    t.string "schedule"
    t.text "slack_channels"
    t.string "state"
    t.datetime "updated_at", null: false
    t.index [ "creator_id" ], name: "index_blazer_checks_on_creator_id"
    t.index [ "query_id" ], name: "index_blazer_checks_on_query_id"
  end

  create_table "blazer_dashboard_queries", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "dashboard_id"
    t.integer "position"
    t.bigint "query_id"
    t.datetime "updated_at", null: false
    t.index [ "dashboard_id" ], name: "index_blazer_dashboard_queries_on_dashboard_id"
    t.index [ "query_id" ], name: "index_blazer_dashboard_queries_on_query_id"
  end

  create_table "blazer_dashboards", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "creator_id"
    t.text "name"
    t.datetime "updated_at", null: false
    t.index [ "creator_id" ], name: "index_blazer_dashboards_on_creator_id"
  end

  create_table "blazer_queries", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "creator_id"
    t.string "data_source"
    t.text "description"
    t.string "name"
    t.text "statement"
    t.datetime "updated_at", null: false
    t.index [ "creator_id" ], name: "index_blazer_queries_on_creator_id"
  end

  create_table "contact_messages", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.string "phone"
    t.text "message", null: false
    t.string "ip"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "credit_bundles", force: :cascade do |t|
    t.decimal "breads_per_week", precision: 8, scale: 2, default: "1.0", null: false
    t.datetime "created_at", null: false
    t.integer "credits", null: false
    t.string "description"
    t.string "name"
    t.decimal "price", precision: 8, scale: 2, null: false
    t.integer "sort_order"
    t.datetime "updated_at", null: false
  end

  create_table "credit_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "good_for_weeks"
    t.string "memo"
    t.integer "quantity"
    t.decimal "stripe_charge_amount", precision: 8, scale: 2
    t.string "stripe_charge_id"
    t.string "stripe_receipt_url"
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index [ "user_id" ], name: "index_credit_items_on_user_id"
  end

  create_table "dyno_metrics", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "dyno", null: false
    t.text "errors_summary"
    t.float "memory_quota"
    t.float "memory_rss"
    t.float "memory_swap"
    t.float "memory_total"
    t.integer "r14_count", default: 0
    t.datetime "recorded_at", null: false
    t.datetime "updated_at", null: false
    t.index [ "dyno", "recorded_at" ], name: "index_dyno_metrics_on_dyno_and_recorded_at"
    t.index [ "recorded_at" ], name: "index_dyno_metrics_on_recorded_at"
  end

  create_table "error_events", force: :cascade do |t|
    t.text "backtrace"
    t.jsonb "context", default: {}, null: false
    t.datetime "created_at", null: false
    t.string "environment"
    t.string "error_class"
    t.string "fingerprint", null: false
    t.string "http_method"
    t.text "message"
    t.datetime "occurred_at", null: false
    t.string "release"
    t.jsonb "request_data", default: {}, null: false
    t.string "request_id"
    t.datetime "resolved_at"
    t.string "source", null: false
    t.integer "status_code"
    t.datetime "updated_at", null: false
    t.string "url"
    t.bigint "user_id"
    t.index [ "fingerprint", "occurred_at" ], name: "index_error_events_on_fingerprint_and_occurred_at"
    t.index [ "occurred_at" ], name: "index_error_events_on_occurred_at"
    t.index [ "resolved_at" ], name: "index_error_events_on_resolved_at"
    t.index [ "source" ], name: "index_error_events_on_source"
    t.index [ "user_id" ], name: "index_error_events_on_user_id"
  end

  create_table "feedbacks", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email"
    t.text "message", null: false
    t.string "source", null: false
    t.string "url"
    t.string "user_agent"
  end

  create_table "items", force: :cascade do |t|
    t.datetime "archived_at"
    t.datetime "created_at", null: false
    t.integer "credits", default: 1, null: false
    t.text "description"
    t.string "name"
    t.decimal "price", precision: 8, scale: 2, default: "5.0", null: false
    t.datetime "updated_at", null: false
    t.index "lower((name)::text)", name: "index_items_on_LOWER_name"
  end

  create_table "menu_item_pickup_days", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "limit"
    t.bigint "menu_item_id", null: false
    t.bigint "pickup_day_id", null: false
    t.datetime "updated_at", null: false
    t.index [ "menu_item_id", "pickup_day_id" ], name: "index_menu_item_pickup_days_on_menu_item_id_and_pickup_day_id", unique: true
    t.index [ "menu_item_id" ], name: "index_menu_item_pickup_days_on_menu_item_id"
    t.index [ "pickup_day_id" ], name: "index_menu_item_pickup_days_on_pickup_day_id"
  end

  create_table "menu_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "item_id"
    t.boolean "marketplace", default: true
    t.bigint "menu_id"
    t.integer "sort_order"
    t.boolean "subscriber", default: true
    t.datetime "updated_at", null: false
    t.index [ "item_id" ], name: "index_menu_items_on_item_id"
    t.index [ "menu_id" ], name: "index_menu_items_on_menu_id"
  end

  create_table "menus", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "day_of_note"
    t.datetime "emailed_at", precision: nil
    t.text "menu_note"
    t.string "menu_type", default: "regular", null: false
    t.string "name"
    t.text "subscriber_note"
    t.datetime "updated_at", null: false
    t.string "week_id", null: false
    t.index [ "week_id", "menu_type" ], name: "index_menus_on_week_id_and_menu_type", unique: true
  end

  create_table "order_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "credits", null: false
    t.bigint "item_id"
    t.bigint "order_id"
    t.bigint "pickup_day_id", null: false
    t.decimal "price", precision: 8, scale: 2, null: false
    t.integer "quantity", default: 1, null: false
    t.datetime "updated_at", null: false
    t.index [ "item_id" ], name: "index_order_items_on_item_id"
    t.index [ "order_id" ], name: "index_order_items_on_order_id"
  end

  create_table "orders", force: :cascade do |t|
    t.bigint "ahoy_visit_id"
    t.text "comments"
    t.datetime "created_at", null: false
    t.bigint "menu_id"
    t.decimal "stripe_charge_amount", precision: 8, scale: 2
    t.string "stripe_charge_id"
    t.string "stripe_receipt_url"
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index [ "menu_id" ], name: "index_orders_on_menu_id"
    t.index [ "user_id" ], name: "index_orders_on_user_id"
  end

  create_table "pickup_days", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "menu_id", null: false
    t.datetime "order_deadline_at", precision: nil, null: false
    t.datetime "pickup_at", precision: nil, null: false
    t.datetime "updated_at", null: false
    t.index [ "menu_id" ], name: "index_pickup_days_on_menu_id"
  end

  create_table "settings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "value"
    t.string "var", null: false
    t.index [ "var" ], name: "index_settings_on_var", unique: true
  end

  create_table "solid_cable_messages", force: :cascade do |t|
    t.binary "channel", null: false
    t.bigint "channel_hash", null: false
    t.datetime "created_at", null: false
    t.binary "payload", null: false
    t.index [ "channel" ], name: "index_solid_cable_messages_on_channel"
    t.index [ "channel_hash" ], name: "index_solid_cable_messages_on_channel_hash"
    t.index [ "created_at" ], name: "index_solid_cable_messages_on_created_at"
  end

  create_table "solid_cache_entries", force: :cascade do |t|
    t.integer "byte_size", null: false
    t.datetime "created_at", null: false
    t.binary "key", null: false
    t.bigint "key_hash", null: false
    t.binary "value", null: false
    t.index [ "byte_size" ], name: "index_solid_cache_entries_on_byte_size"
    t.index [ "key_hash", "byte_size" ], name: "index_solid_cache_entries_on_key_hash_and_byte_size"
    t.index [ "key_hash" ], name: "index_solid_cache_entries_on_key_hash", unique: true
  end

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.string "concurrency_key", null: false
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.index [ "concurrency_key", "priority", "job_id" ], name: "index_solid_queue_blocked_executions_for_release"
    t.index [ "expires_at", "concurrency_key" ], name: "index_solid_queue_blocked_executions_for_maintenance"
    t.index [ "job_id" ], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.bigint "process_id"
    t.index [ "job_id" ], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index [ "process_id", "job_id" ], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "error"
    t.bigint "job_id", null: false
    t.index [ "job_id" ], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "active_job_id"
    t.text "arguments"
    t.string "class_name", null: false
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "finished_at"
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at"
    t.datetime "updated_at", null: false
    t.index [ "active_job_id" ], name: "index_solid_queue_jobs_on_active_job_id"
    t.index [ "class_name" ], name: "index_solid_queue_jobs_on_class_name"
    t.index [ "finished_at" ], name: "index_solid_queue_jobs_on_finished_at"
    t.index [ "queue_name", "finished_at" ], name: "index_solid_queue_jobs_for_filtering"
    t.index [ "scheduled_at", "finished_at" ], name: "index_solid_queue_jobs_for_alerting"
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "queue_name", null: false
    t.index [ "queue_name" ], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "hostname"
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.text "metadata"
    t.string "name", null: false
    t.integer "pid", null: false
    t.bigint "supervisor_id"
    t.index [ "last_heartbeat_at" ], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index [ "name", "supervisor_id" ], name: "index_solid_queue_processes_on_name_and_supervisor_id", unique: true
    t.index [ "supervisor_id" ], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.index [ "job_id" ], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index [ "priority", "job_id" ], name: "index_solid_queue_poll_all"
    t.index [ "queue_name", "priority", "job_id" ], name: "index_solid_queue_poll_by_queue"
  end

  create_table "solid_queue_recurring_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.datetime "run_at", null: false
    t.string "task_key", null: false
    t.index [ "job_id" ], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    t.index [ "task_key", "run_at" ], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
  end

  create_table "solid_queue_recurring_tasks", force: :cascade do |t|
    t.text "arguments"
    t.string "class_name"
    t.string "command", limit: 2048
    t.datetime "created_at", null: false
    t.text "description"
    t.string "key", null: false
    t.integer "priority", default: 0
    t.string "queue_name"
    t.string "schedule", null: false
    t.boolean "static", default: true, null: false
    t.datetime "updated_at", null: false
    t.index [ "key" ], name: "index_solid_queue_recurring_tasks_on_key", unique: true
    t.index [ "static" ], name: "index_solid_queue_recurring_tasks_on_static"
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at", null: false
    t.index [ "job_id" ], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index [ "scheduled_at", "priority", "job_id" ], name: "index_solid_queue_dispatch_all"
  end

  create_table "solid_queue_semaphores", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.integer "value", default: 1, null: false
    t.index [ "expires_at" ], name: "index_solid_queue_semaphores_on_expires_at"
    t.index [ "key", "value" ], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index [ "key" ], name: "index_solid_queue_semaphores_on_key", unique: true
  end

  create_table "uptime_checks", force: :cascade do |t|
    t.datetime "checked_at", null: false
    t.datetime "created_at", null: false
    t.string "error"
    t.integer "latency_ms"
    t.integer "status"
    t.string "target", null: false
    t.boolean "up", default: false, null: false
    t.datetime "updated_at", null: false
    t.string "url", null: false
    t.index [ "target", "checked_at" ], name: "index_uptime_checks_on_target_and_checked_at"
  end

  create_table "users", force: :cascade do |t|
    t.string "additional_email"
    t.decimal "breads_per_week", default: "1.0", null: false
    t.datetime "created_at", null: false
    t.datetime "current_sign_in_at", precision: nil
    t.inet "current_sign_in_ip"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "first_name"
    t.boolean "is_admin"
    t.string "last_name"
    t.datetime "last_sign_in_at", precision: nil
    t.inet "last_sign_in_ip"
    t.boolean "mailing_list", default: false, null: false
    t.string "phone"
    t.boolean "receive_day_of_reminder", default: true, null: false
    t.boolean "receive_havent_ordered_reminder", default: true, null: false
    t.boolean "receive_weekly_menu", default: false, null: false
    t.datetime "remember_created_at", precision: nil
    t.datetime "reset_password_sent_at", precision: nil
    t.string "reset_password_token"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index "lower((first_name)::text), lower((last_name)::text)", name: "index_users_on_LOWER_first_name_LOWER_last_name"
    t.index [ "email" ], name: "index_users_on_email", unique: true
    t.index [ "reset_password_token" ], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "versions", force: :cascade do |t|
    t.datetime "created_at", precision: nil
    t.string "event", null: false
    t.bigint "item_id", null: false
    t.string "item_type", null: false
    t.text "object"
    t.text "object_changes"
    t.string "whodunnit"
    t.index [ "item_type", "item_id" ], name: "index_versions_on_item_type_and_item_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "activity_events", "users"
  add_foreign_key "analysis_replies", "anomaly_analyses"
  add_foreign_key "analysis_replies", "users"
  add_foreign_key "anomaly_analyses", "users"
  add_foreign_key "error_events", "users"
  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
end
