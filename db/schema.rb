# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20130304200122) do

  create_table "active_admin_comments", :force => true do |t|
    t.string   "resource_id",   :null => false
    t.string   "resource_type", :null => false
    t.integer  "author_id"
    t.string   "author_type"
    t.text     "body"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
    t.string   "namespace"
  end

  add_index "active_admin_comments", ["author_type", "author_id"], :name => "index_active_admin_comments_on_author_type_and_author_id"
  add_index "active_admin_comments", ["namespace"], :name => "index_active_admin_comments_on_namespace"
  add_index "active_admin_comments", ["resource_type", "resource_id"], :name => "index_admin_notes_on_resource_type_and_resource_id"

  create_table "asset_collections", :force => true do |t|
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "assets", :force => true do |t|
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "church_names", :force => true do |t|
    t.string   "chapman_code"
    t.string   "parish"
    t.string   "church"
    t.string   "toponym"
    t.boolean  "resolved"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
  end

  create_table "churches", :force => true do |t|
    t.string   "church_name"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  create_table "emendation_rules", :force => true do |t|
    t.string   "source"
    t.string   "target"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "emendation_types", :force => true do |t|
    t.string   "target_field"
    t.string   "name"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
  end

  create_table "entities", :force => true do |t|
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "fields", :force => true do |t|
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "freereg1_csv_entries", :force => true do |t|
    t.string   "abode"
    t.string   "age"
    t.string   "baptdate"
    t.string   "birthdate"
    t.string   "bride_abode"
    t.string   "bride_age"
    t.string   "bride_condition"
    t.string   "bride_fath_firstname"
    t.string   "bride_fath_occupation"
    t.string   "bride_fath_surname"
    t.string   "bride_firstname"
    t.string   "bride_occupation"
    t.string   "bride_parish"
    t.string   "bride_surname"
    t.string   "burdate"
    t.string   "church"
    t.string   "county"
    t.string   "father"
    t.string   "fath_occupation"
    t.string   "fath_surname"
    t.string   "firstname"
    t.string   "groom_abode"
    t.string   "groom_age"
    t.string   "groom_condition"
    t.string   "groom_fath_firstname"
    t.string   "groom_fath_occupation"
    t.string   "groom_fath_surname"
    t.string   "groom_firstname"
    t.string   "groom_occupation"
    t.string   "groom_parish"
    t.string   "groom_surname"
    t.string   "marrdate"
    t.string   "mother"
    t.string   "moth_surname"
    t.string   "no"
    t.string   "notes"
    t.string   "place"
    t.string   "rel1_male_first"
    t.string   "rel1_surname"
    t.string   "rel2_female_first"
    t.string   "relationship"
    t.string   "sex"
    t.string   "surname"
    t.string   "witness1_firstname"
    t.string   "witness1_surname"
    t.string   "witness2_firstname"
    t.string   "witness2_surname"
    t.datetime "created_at",            :null => false
    t.datetime "updated_at",            :null => false
  end

  create_table "freereg1_csv_files", :force => true do |t|
    t.string   "dir_name"
    t.string   "file_name"
    t.string   "transcriber_email"
    t.string   "transcriber_name"
    t.string   "transcriber_syndicate"
    t.string   "transcription_date"
    t.string   "record_type"
    t.string   "credit_name"
    t.string   "credit_email"
    t.string   "first_comment"
    t.string   "second_comment"
    t.datetime "created_at",            :null => false
    t.datetime "updated_at",            :null => false
  end

  create_table "image_dirs", :force => true do |t|
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "image_files", :force => true do |t|
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "image_lists", :force => true do |t|
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "image_upload_logs", :force => true do |t|
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "image_uploads", :force => true do |t|
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "places", :force => true do |t|
    t.string   "chapman_code"
    t.string   "place_name"
    t.string   "church_name"
    t.string   "genuki_url"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
  end

  create_table "registers", :force => true do |t|
    t.string   "start_year"
    t.string   "end_year"
    t.string   "register_type"
    t.string   "status"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  create_table "s3buckets", :force => true do |t|
    t.string   "name"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "search_names", :force => true do |t|
    t.string   "first_name"
    t.string   "last_name"
    t.string   "role"
    t.string   "origin"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "search_queries", :force => true do |t|
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "search_records", :force => true do |t|
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "templates", :force => true do |t|
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "toponyms", :force => true do |t|
    t.string   "chapman_code"
    t.string   "parish"
    t.string   "geonames_response"
    t.string   "gbhgis_response"
    t.boolean  "resolved"
    t.datetime "created_at",        :null => false
    t.datetime "updated_at",        :null => false
  end

end
