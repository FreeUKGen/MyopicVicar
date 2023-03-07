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
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20200819183253) do

  create_table "accessions", primary_key: "AccessionNumber", id: :integer, unsigned: true, default: nil, force: :cascade, options: "ENGINE=MyISAM DEFAULT CHARSET=latin1" do |t|
    t.integer "FileNumber", limit: 3, null: false, unsigned: true
    t.integer "StartLine", limit: 3, null: false, unsigned: true
    t.integer "Count", limit: 3, unsigned: true
    t.integer "LastSeqNumber", limit: 3, unsigned: true
    t.string "FirstName", limit: 50
    t.string "FirstGivenname", limit: 100
    t.string "LastName", limit: 50
    t.integer "Year", limit: 2, null: false
    t.integer "EntryQuarter", limit: 1, null: false
    t.string "Page", limit: 20
    t.integer "Incomplete", limit: 1, default: 0
    t.string "SourceType", limit: 2
    t.string "SourceID", limit: 200
    t.string "TransDate", limit: 50
    t.integer "FromFiche", limit: 2, null: false
    t.string "FicheRange", limit: 50
    t.string "FicheNumber", limit: 50, default: ""
    t.integer "RecordTypeID", limit: 1, null: false
    t.integer "Supersedes", default: 0
    t.index ["EntryQuarter"], name: "EntryQuarter"
    t.index ["FileNumber"], name: "FileNumber"
    t.index ["Supersedes"], name: "Supersedes"
    t.index ["Year", "EntryQuarter", "RecordTypeID"], name: "Year"
    t.index ["Year"], name: "Year_2"
  end

  create_table "ageatdeath", id: false, force: :cascade, options: "ENGINE=MyISAM DEFAULT CHARSET=latin1" do |t|
    t.integer "RecordNumber", null: false
    t.integer "EarliestQuarter", null: false
    t.integer "LatestQuarter", null: false
    t.integer "YoungestMonth", null: false
    t.integer "OldestMonth", null: false
    t.integer "Recorded", limit: 1, default: 0
    t.index ["EarliestQuarter"], name: "EarliestQuarter"
    t.index ["LatestQuarter"], name: "LatestQuarter"
    t.index ["OldestMonth"], name: "OldestMonth"
    t.index ["RecordNumber"], name: "RecordNumber"
    t.index ["Recorded"], name: "Recorded"
    t.index ["YoungestMonth"], name: "YoungestMonth"
  end

  create_table "alignments", id: false, force: :cascade, options: "ENGINE=MyISAM DEFAULT CHARSET=latin1" do |t|
    t.decimal "TimeStamp", precision: 12
    t.integer "Differentiator", default: 0
    t.integer "RecordType", limit: 1, null: false
    t.integer "YearQuarterType", null: false
    t.text "RecordInfo", null: false
    t.index ["TimeStamp"], name: "TimeStamp"
  end

  create_table "allfiles", primary_key: "FileNumber", id: :integer, unsigned: true, default: nil, force: :cascade, options: "ENGINE=MyISAM DEFAULT CHARSET=latin1" do |t|
    t.integer "SubmitterNumber", null: false
    t.string "FileName", limit: 150, null: false, collation: "latin1_bin"
    t.string "CreditName", collation: "latin1_bin"
    t.string "CreditEmail"
    t.string "CreditText"
    t.integer "FileType", limit: 1
    t.integer "Flat", limit: 1, default: 0
    t.string "Syndicate", limit: 50
    t.integer "SyndicateGroup", default: -1
    t.decimal "Created", precision: 12
    t.integer "Locked", limit: 1, default: 0
    t.decimal "LockedDate", precision: 12
    t.text "LockedReason"
    t.decimal "SyndChanged", precision: 12, default: "0"
    t.integer "Supersedes", default: 0
    t.boolean "Current"
    t.decimal "DatabaseVersion", precision: 12
    t.boolean "Amended", default: false
    t.boolean "Deleted", default: false
    t.boolean "Excluded", default: false
    t.decimal "MetadataLastModified", precision: 12, default: "0"
    t.string "FirstSurname", limit: 50
    t.string "FirstPage", limit: 20
    t.integer "EntryCount"
    t.index ["FileName"], name: "FileName"
    t.index ["SubmitterNumber"], name: "SubmitterNumber"
    t.index ["SyndicateGroup"], name: "SyndicateGroup"
  end

  create_table "bestguess", primary_key: "RecordNumber", id: :integer, unsigned: true, default: nil, force: :cascade, options: "ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_german1_ci MAX_ROWS=300000000 AVG_ROW_LENGTH=80" do |t|
    t.integer "ChunkNumber", null: false, unsigned: true
    t.integer "SuperChunk", limit: 2, null: false, unsigned: true
    t.integer "Confirmed", limit: 2, null: false, unsigned: true
    t.string "Surname", limit: 50, null: false
    t.string "SurnameSx", limit: 4, null: false
    t.string "GivenName", limit: 100, null: false
    t.string "OtherNames", limit: 100, null: false
    t.string "AgeAtDeath", limit: 50
    t.string "AssociateName", limit: 50
    t.integer "DistrictNumber", limit: 2, null: false, unsigned: true
    t.string "District", limit: 70, null: false
    t.integer "DistrictFlag", limit: 1, null: false, unsigned: true
    t.integer "CountyComboID", limit: 2, unsigned: true
    t.string "Volume", limit: 20, null: false
    t.string "Page", limit: 20, null: false
    t.integer "RecordTypeID", limit: 1, null: false
    t.integer "QuarterNumber", limit: 2, null: false
    t.index ["AssociateName", "QuarterNumber"], name: "AssociateName"
    t.index ["ChunkNumber"], name: "ChunkNumber"
    t.index ["DistrictNumber", "QuarterNumber"], name: "DistrictNumber"
    t.index ["GivenName", "QuarterNumber"], name: "GivenName", length: { GivenName: 10 }
    t.index ["OtherNames", "QuarterNumber"], name: "OtherNames", length: { OtherNames: 10 }
    t.index ["QuarterNumber", "GivenName"], name: "QuarterNumber", length: { GivenName: 10 }
    t.index ["Surname", "DistrictNumber"], name: "Surname_4", length: { Surname: 10 }
    t.index ["Surname", "GivenName", "DistrictNumber"], name: "Surname_2", length: { Surname: 10, GivenName: 10 }
    t.index ["Surname", "GivenName", "QuarterNumber"], name: "Surname", length: { Surname: 10, GivenName: 10 }
    t.index ["Surname", "QuarterNumber"], name: "Surname_3", length: { Surname: 10 }
    t.index ["SurnameSx", "DistrictNumber"], name: "SurnameSx_4"
    t.index ["SurnameSx", "GivenName", "DistrictNumber"], name: "SurnameSx_2", length: { GivenName: 10 }
    t.index ["SurnameSx", "GivenName", "QuarterNumber"], name: "SurnameSx", length: { GivenName: 10 }
    t.index ["SurnameSx", "QuarterNumber"], name: "SurnameSx_3"
    t.index ["Volume", "Page", "QuarterNumber"], name: "Volume"
  end

  create_table "bestguesschunk", primary_key: ["ChunkNumber", "AccessionNumber"], force: :cascade, options: "ENGINE=MyISAM DEFAULT CHARSET=latin1" do |t|
    t.integer "ChunkNumber", null: false, unsigned: true
    t.integer "AccessionNumber", null: false, unsigned: true
    t.integer "SuperChunk", limit: 2, null: false, unsigned: true
    t.integer "QuarterNumberEvent", limit: 2, null: false, unsigned: true
    t.index ["AccessionNumber"], name: "AccessionNumber"
    t.index ["QuarterNumberEvent"], name: "QuarterNumberEvent"
  end

  create_table "bestguesshash", id: false, force: :cascade, options: "ENGINE=MyISAM DEFAULT CHARSET=latin1" do |t|
    t.integer "RecordNumber", null: false
    t.string "Hash", limit: 22, null: false, collation: "latin1_bin"
    t.index ["Hash"], name: "Hash"
  end

  create_table "bestguesslink", primary_key: ["RecordNumber", "AccessionNumber", "SequenceNumber"], force: :cascade, options: "ENGINE=MyISAM DEFAULT CHARSET=latin1" do |t|
    t.integer "RecordNumber", null: false, unsigned: true
    t.integer "AccessionNumber", null: false
    t.integer "SequenceNumber", limit: 2, null: false, unsigned: true
    t.integer "PrimaryEntry", limit: 2, default: 0
    t.index ["AccessionNumber", "SequenceNumber"], name: "AccessionNumber"
    t.index ["RecordNumber"], name: "RecordNumber"
  end

  create_table "bestguessmarriages", primary_key: "RecordNumber", id: :integer, unsigned: true, default: nil, force: :cascade, options: "ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_german1_ci MAX_ROWS=100000000 AVG_ROW_LENGTH=70" do |t|
    t.integer "ChunkNumber", null: false, unsigned: true
    t.integer "SuperChunk", limit: 2, null: false, unsigned: true
    t.integer "Confirmed", limit: 2, null: false, unsigned: true
    t.string "Surname", limit: 50, null: false
    t.string "SurnameSx", limit: 4, null: false
    t.string "GivenName", limit: 100, null: false
    t.string "OtherNames", limit: 100, null: false
    t.string "AgeAtDeath", limit: 50
    t.string "AssociateName", limit: 50
    t.integer "DistrictNumber", limit: 2, null: false, unsigned: true
    t.string "District", limit: 70, null: false
    t.integer "DistrictFlag", limit: 1, null: false, unsigned: true
    t.integer "CountyComboID", limit: 2, unsigned: true
    t.string "Volume", limit: 20, null: false
    t.string "Page", limit: 20, null: false
    t.integer "RecordTypeID", limit: 1, null: false
    t.integer "QuarterNumber", limit: 2, null: false
    t.index ["AssociateName", "QuarterNumber"], name: "AssociateName"
    t.index ["ChunkNumber"], name: "ChunkNumber"
    t.index ["DistrictNumber", "QuarterNumber"], name: "DistrictNumber"
    t.index ["GivenName", "QuarterNumber"], name: "GivenName", length: { GivenName: 10 }
    t.index ["OtherNames", "QuarterNumber"], name: "OtherNames", length: { OtherNames: 10 }
    t.index ["QuarterNumber", "GivenName"], name: "QuarterNumber", length: { GivenName: 10 }
    t.index ["Surname", "DistrictNumber"], name: "Surname_4", length: { Surname: 10 }
    t.index ["Surname", "GivenName", "DistrictNumber"], name: "Surname_2", length: { Surname: 10, GivenName: 10 }
    t.index ["Surname", "GivenName", "QuarterNumber"], name: "Surname", length: { Surname: 10, GivenName: 10 }
    t.index ["Surname", "QuarterNumber"], name: "Surname_3", length: { Surname: 10 }
    t.index ["SurnameSx", "DistrictNumber"], name: "SurnameSx_4"
    t.index ["SurnameSx", "GivenName", "DistrictNumber"], name: "SurnameSx_2", length: { GivenName: 10 }
    t.index ["SurnameSx", "GivenName", "QuarterNumber"], name: "SurnameSx", length: { GivenName: 10 }
    t.index ["SurnameSx", "QuarterNumber"], name: "SurnameSx_3"
    t.index ["Volume", "Page", "QuarterNumber"], name: "Volume"
  end

  create_table "bestguessquarters", primary_key: "QuarterNumberEvent", id: :integer, limit: 2, unsigned: true, default: nil, force: :cascade, options: "ENGINE=MyISAM DEFAULT CHARSET=latin1" do |t|
    t.integer "RecordNumberMin", null: false
    t.integer "RecordNumberMax", null: false
    t.integer "NewRecordCount", null: false
  end

  create_table "commentlink", id: false, force: :cascade, options: "ENGINE=MyISAM DEFAULT CHARSET=latin1" do |t|
    t.integer "AccessionNumber", null: false, unsigned: true
    t.integer "SequenceNumber", null: false, unsigned: true
    t.integer "CommentID", null: false, unsigned: true
    t.integer "Year", limit: 2
    t.integer "EntryQuarter", limit: 1
    t.integer "RecordTypeID", limit: 1
    t.index ["AccessionNumber", "SequenceNumber"], name: "AccessionNumber_2"
    t.index ["AccessionNumber"], name: "AccessionNumber"
    t.index ["CommentID"], name: "CommentID"
    t.index ["RecordTypeID", "Year", "EntryQuarter"], name: "RecordTypeID"
    t.index ["Year", "EntryQuarter"], name: "Year"
  end

  create_table "comments", id: false, force: :cascade, options: "ENGINE=MyISAM DEFAULT CHARSET=latin1" do |t|
    t.integer "CommentID", null: false
    t.text "CommentText"
    t.index ["CommentID"], name: "CommentID"
  end

  create_table "componentfile", id: false, force: :cascade, options: "ENGINE=MyISAM DEFAULT CHARSET=latin1" do |t|
    t.integer "ImageID", null: false, unsigned: true
    t.string "Filename", limit: 150, collation: "latin1_bin"
    t.index ["ImageID"], name: "ImageID"
  end

  create_table "countycombos", id: false, force: :cascade, options: "ENGINE=MyISAM DEFAULT CHARSET=latin1" do |t|
    t.string "County", limit: 3, null: false
    t.integer "CountyComboID", null: false, unsigned: true
  end

  create_table "coverage", primary_key: "QuarterNumberEvent", id: :integer, unsigned: true, default: nil, force: :cascade, options: "ENGINE=MyISAM DEFAULT CHARSET=latin1" do |t|
    t.integer "Percentage", limit: 2, null: false, unsigned: true
  end

  create_table "districtpseudonyms", id: false, force: :cascade, options: "ENGINE=MyISAM DEFAULT CHARSET=latin1" do |t|
    t.integer "DistrictNumber", null: false, unsigned: true
    t.string "DistrictPseudonym", limit: 70, null: false
    t.integer "Assumed", limit: 1, default: 0
  end

  create_table "districts", primary_key: "DistrictNumber", id: :integer, limit: 3, unsigned: true, force: :cascade, options: "ENGINE=MyISAM DEFAULT CHARSET=latin1" do |t|
    t.string "DistrictName", limit: 70, null: false
    t.integer "Invented", limit: 1, null: false
    t.string "InfoPage", limit: 3
    t.text "InfoBookmark"
    t.integer "YearStart", limit: 2
    t.integer "QuarterStart", limit: 1
    t.integer "YearEnd", limit: 2
    t.integer "QuarterEnd", limit: 1
    t.string "Volume1837to1851", limit: 2
    t.string "Volume1852to1945", limit: 3
    t.string "Volume1946to1965", limit: 3
    t.string "Volume1966to1973", limit: 3
    t.string "Volume1974to1993_4", limit: 3
    t.string "Volume1993_4toEnd", limit: 3
    t.integer "UsageCount", default: 0
    t.index ["DistrictName"], name: "DistrictName", unique: true
  end

  create_table "districtsynonyms", primary_key: "SynonymNumber", id: :integer, unsigned: true, force: :cascade, options: "ENGINE=MyISAM DEFAULT CHARSET=latin1" do |t|
    t.integer "DistrictNumber", null: false, unsigned: true
    t.string "DistrictName", limit: 70, null: false
    t.integer "Alias", limit: 1, null: false
    t.integer "Misspelt", limit: 1, null: false
    t.integer "Invented", limit: 1, null: false
    t.integer "Dated", limit: 1, null: false
    t.string "Volume", limit: 20, null: false
    t.index ["DistrictName", "Volume", "SynonymNumber"], name: "DistrictName"
  end

  create_table "districttocounty", primary_key: ["DistrictNumber", "County"], force: :cascade, options: "ENGINE=MyISAM DEFAULT CHARSET=latin1" do |t|
    t.integer "DistrictNumber", null: false, unsigned: true
    t.string "County", limit: 3, null: false
    t.integer "StartQN"
    t.integer "EndQN"
  end

  create_table "districttocountycombo", id: false, force: :cascade, options: "ENGINE=MyISAM DEFAULT CHARSET=latin1" do |t|
    t.integer "DistrictNumber", null: false, unsigned: true
    t.integer "CountyComboID", null: false, unsigned: true
    t.integer "StartQN"
    t.integer "EndQN"
  end

  create_table "filesyndicates", id: false, force: :cascade, options: "ENGINE=MyISAM DEFAULT CHARSET=latin1" do |t|
    t.integer "SyndicateGroup", null: false, unsigned: true
    t.string "SyndicateName", limit: 50, null: false
    t.index ["SyndicateGroup"], name: "SyndicateGroup"
  end

  create_table "imagefile", id: false, force: :cascade, options: "ENGINE=MyISAM DEFAULT CHARSET=latin1" do |t|
    t.integer "ImageID", null: false, unsigned: true
    t.integer "RangeID"
    t.string "FileName", limit: 150, collation: "latin1_bin"
    t.string "StartLetters", limit: 10
    t.string "EndLetters", limit: 10
    t.integer "SequenceOrder"
    t.integer "Excluded", limit: 1, default: 0
    t.integer "ParseFailed", limit: 1, default: 0
    t.integer "MultipleFiles", limit: 1, default: 0
    t.index ["ImageID"], name: "ImageID"
    t.index ["RangeID", "FileName"], name: "RangeID_2", unique: true
    t.index ["RangeID"], name: "RangeID"
    t.index ["SequenceOrder"], name: "SequenceOrder"
  end

  create_table "imagepage", id: false, force: :cascade, options: "ENGINE=MyISAM DEFAULT CHARSET=latin1" do |t|
    t.integer "ImageID"
    t.string "PageNumber", limit: 20
    t.integer "Implied", limit: 1, default: 0
    t.index ["ImageID"], name: "ImageID"
  end

  create_table "postems", id: false, force: :cascade, options: "ENGINE=MyISAM DEFAULT CHARSET=latin1" do |t|
    t.integer "PostemID", null: false, auto_increment: true
    t.integer "QuarterNumberEvent", null: false, unsigned: true
    t.string "Hash", limit: 22, null: false, collation: "latin1_bin"
    t.string "RecordInfo", limit: 250
    t.text "Information"
    t.decimal "Created", precision: 12
    t.string "SourceInfo", limit: 250
    t.integer "PostemFlags", limit: 1, default: 0, unsigned: true
    t.index ["Hash"], name: "Hash"
    t.index ["PostemFlags"], name: "PostemFlags"
    t.index ["PostemID"], name: "PostemID"
    t.index ["QuarterNumberEvent"], name: "QuarterNumberEvent"
  end

  create_table "range", primary_key: "RangeID", id: :integer, unsigned: true, default: nil, force: :cascade, options: "ENGINE=MyISAM DEFAULT CHARSET=latin1" do |t|
    t.integer "SourceID"
    t.string "Range", limit: 50
    t.string "StartLetters", limit: 10
    t.string "EndLetters", limit: 10
    t.integer "StartPage", default: 0, unsigned: true
    t.integer "EndPage", default: 0, unsigned: true
    t.integer "QualityAverage", limit: 2, default: 0, unsigned: true
    t.integer "QualitySample", limit: 2, default: 0, unsigned: true
    t.integer "FileCount"
    t.index ["Range", "SourceID"], name: "Range", unique: true
    t.index ["SourceID"], name: "SourceID"
  end

  create_table "rangestatistics", id: false, force: :cascade, options: "ENGINE=MyISAM DEFAULT CHARSET=latin1" do |t|
    t.integer "SyndicateID", null: false, unsigned: true
    t.integer "Year", limit: 2, null: false
    t.string "RangeQuarter", limit: 1, null: false
    t.integer "RecordTypeID", limit: 1, null: false
    t.string "StartName", limit: 50
    t.string "EndName", limit: 50
    t.integer "TotalEntries"
    t.integer "SyndicateEntries"
  end

  create_table "recordtypes", primary_key: "RecordTypeID", id: :integer, limit: 1, default: nil, force: :cascade, options: "ENGINE=MyISAM DEFAULT CHARSET=latin1" do |t|
    t.string "RecordType", limit: 50
  end

  create_table "refinery_authentication_devise_roles", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci" do |t|
    t.string "title"
  end

  create_table "refinery_authentication_devise_roles_users", id: false, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci" do |t|
    t.integer "user_id"
    t.integer "role_id"
    t.index ["role_id", "user_id"], name: "refinery_roles_users_role_id_user_id"
    t.index ["user_id", "role_id"], name: "refinery_roles_users_user_id_role_id"
  end

  create_table "refinery_authentication_devise_user_plugins", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci" do |t|
    t.integer "user_id"
    t.string "name"
    t.integer "position"
    t.index ["name"], name: "index_refinery_authentication_devise_user_plugins_on_name"
    t.index ["user_id", "name"], name: "refinery_user_plugins_user_id_name", unique: true
  end

  create_table "refinery_authentication_devise_users", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci" do |t|
    t.string "username", null: false
    t.string "email", null: false
    t.string "encrypted_password", null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.integer "sign_in_count"
    t.datetime "remember_created_at"
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "slug"
    t.string "userid_detail_id"
    t.string "password_salt"
    t.string "full_name"
    t.index ["id"], name: "index_refinery_authentication_devise_users_on_id"
    t.index ["slug"], name: "index_refinery_authentication_devise_users_on_slug"
  end

  create_table "refinery_county_pages", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci" do |t|
    t.string "name"
    t.string "chapman_code"
    t.text "content"
    t.integer "position"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "refinery_image_translations", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci" do |t|
    t.integer "refinery_image_id", null: false
    t.string "locale", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "image_alt"
    t.string "image_title"
    t.index ["locale"], name: "index_refinery_image_translations_on_locale"
    t.index ["refinery_image_id"], name: "index_refinery_image_translations_on_refinery_image_id"
  end

  create_table "refinery_images", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci" do |t|
    t.string "image_mime_type"
    t.string "image_name"
    t.integer "image_size"
    t.integer "image_width"
    t.integer "image_height"
    t.string "image_uid"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "refinery_page_part_translations", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci" do |t|
    t.integer "refinery_page_part_id", null: false
    t.string "locale", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "body", limit: 4294967295
    t.index ["locale"], name: "index_refinery_page_part_translations_on_locale"
    t.index ["refinery_page_part_id"], name: "index_refinery_page_part_translations_on_refinery_page_part_id"
  end

  create_table "refinery_page_parts", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci" do |t|
    t.integer "refinery_page_id"
    t.string "slug"
    t.integer "position"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "title"
    t.index ["id"], name: "index_refinery_page_parts_on_id"
    t.index ["refinery_page_id"], name: "index_refinery_page_parts_on_refinery_page_id"
  end

  create_table "refinery_page_translations", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci" do |t|
    t.integer "refinery_page_id", null: false
    t.string "locale", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "title"
    t.string "custom_slug"
    t.string "menu_title"
    t.string "slug"
    t.index ["locale"], name: "index_refinery_page_translations_on_locale"
    t.index ["refinery_page_id"], name: "index_refinery_page_translations_on_refinery_page_id"
  end

  create_table "refinery_pages", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci" do |t|
    t.integer "parent_id"
    t.string "path"
    t.boolean "show_in_menu", default: true
    t.string "link_url"
    t.string "menu_match"
    t.boolean "deletable", default: true
    t.boolean "draft", default: false
    t.boolean "skip_to_first_child", default: false
    t.integer "lft"
    t.integer "rgt"
    t.integer "depth"
    t.string "view_template"
    t.string "layout_template"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "children_count", default: 0, null: false
    t.index ["depth"], name: "index_refinery_pages_on_depth"
    t.index ["id"], name: "index_refinery_pages_on_id"
    t.index ["lft"], name: "index_refinery_pages_on_lft"
    t.index ["parent_id"], name: "index_refinery_pages_on_parent_id"
    t.index ["rgt"], name: "index_refinery_pages_on_rgt"
  end

  create_table "refinery_resource_translations", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci" do |t|
    t.integer "refinery_resource_id", null: false
    t.string "locale", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "resource_title"
    t.index ["locale"], name: "index_refinery_resource_translations_on_locale"
    t.index ["refinery_resource_id"], name: "index_refinery_resource_translations_on_refinery_resource_id"
  end

  create_table "refinery_resources", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci" do |t|
    t.string "file_mime_type"
    t.string "file_name"
    t.integer "file_size"
    t.string "file_uid"
    t.string "file_ext"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "scanlink", id: false, force: :cascade, options: "ENGINE=MyISAM DEFAULT CHARSET=latin1 MAX_ROWS=10000000" do |t|
    t.integer "ChunkNumber", null: false, unsigned: true
    t.integer "ScanID", null: false
    t.index ["ChunkNumber"], name: "ChunkNumber"
  end

  create_table "scanlist", primary_key: "ScanID", id: :integer, force: :cascade, options: "ENGINE=MyISAM DEFAULT CHARSET=latin1" do |t|
    t.integer "QuarterEventNumber"
    t.string "SeriesRangeFileName", limit: 250, collation: "latin1_bin"
    t.string "Hash", limit: 22, null: false, collation: "latin1_bin"
    t.integer "Definitive", default: 0
    t.integer "Confirmed", default: 0
    t.integer "Rejected", default: 0
    t.integer "Quality"
    t.text "Entry"
    t.integer "Timestamp"
    t.index ["Hash"], name: "Hash"
    t.index ["QuarterEventNumber", "SeriesRangeFileName", "Hash"], name: "QuarterEventNumber_2", unique: true
    t.index ["QuarterEventNumber", "SeriesRangeFileName"], name: "QuarterEventNumber"
  end

  create_table "seo_meta", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci" do |t|
    t.integer "seo_meta_id"
    t.string "seo_meta_type"
    t.string "browser_title"
    t.text "meta_description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["id"], name: "index_seo_meta_on_id"
    t.index ["seo_meta_id", "seo_meta_type"], name: "id_type_index_on_seo_meta"
  end

  create_table "source", primary_key: "SourceID", id: :integer, unsigned: true, default: nil, force: :cascade, options: "ENGINE=MyISAM DEFAULT CHARSET=latin1" do |t|
    t.integer "QuarterEventNumber"
    t.string "SeriesID", limit: 200
    t.index ["QuarterEventNumber", "SeriesID"], name: "QuarterEventNumber", unique: true
  end

  create_table "submissions", primary_key: ["AccessionNumber", "SequenceNumber"], force: :cascade, options: "ENGINE=MyISAM DEFAULT CHARSET=latin1 MAX_ROWS=400000000 AVG_ROW_LENGTH=57" do |t|
    t.integer "AccessionNumber", null: false
    t.integer "SequenceNumber", limit: 3, null: false, unsigned: true
    t.string "Surname", limit: 50, null: false
    t.string "GivenName", limit: 100, null: false
    t.string "AssociateName", limit: 50
    t.string "AgeAtDeath", limit: 50
    t.string "District", limit: 70, null: false
    t.integer "DistrictNumber", limit: 3, null: false, unsigned: true
    t.integer "DistrictFlag", limit: 1, null: false, unsigned: true
    t.string "Volume", limit: 20, null: false
    t.string "RomanVolume", limit: 20, null: false
    t.string "Page", limit: 20, null: false
    t.integer "EntryFlag", limit: 1
    t.integer "CommentID"
    t.string "Registered", limit: 10
    t.index ["AccessionNumber", "RomanVolume"], name: "AccessionNumber_2"
    t.index ["AccessionNumber"], name: "AccessionNumber"
    t.index ["CommentID"], name: "CommentID"
    t.index ["District"], name: "District"
    t.index ["DistrictNumber"], name: "DistrictNumber"
    t.index ["Page"], name: "Page"
    t.index ["RomanVolume"], name: "RomanVolume"
    t.index ["SequenceNumber"], name: "SequenceNumber"
    t.index ["Surname", "GivenName"], name: "Surname", length: { Surname: 10, GivenName: 10 }
  end

  create_table "submitterinfo", primary_key: "SubmitterNumber", id: :integer, unsigned: true, default: nil, force: :cascade, options: "ENGINE=MyISAM DEFAULT CHARSET=latin1" do |t|
    t.string "UserID", limit: 50, null: false, collation: "latin1_bin"
  end

  create_table "submitters", primary_key: "SubmitterNumber", id: :integer, unsigned: true, force: :cascade, options: "ENGINE=MyISAM DEFAULT CHARSET=latin1" do |t|
    t.decimal "SignUpDate", precision: 12, default: "0"
    t.integer "NewlyEntered", limit: 2, null: false
    t.integer "ChallengeRequired", limit: 2, default: 0
    t.decimal "EnabledDate", precision: 12
    t.decimal "LastLogin", precision: 12, default: "-1"
    t.integer "LastLoginFlag", limit: 1, default: 0
    t.decimal "LastAdminLogin", precision: 12, default: "0"
    t.integer "Disabled", limit: 2, default: 0, null: false
    t.decimal "DisabledDate", precision: 12, default: "0"
    t.string "DisabledReason", limit: 250
    t.integer "Locked", limit: 1, default: 0
    t.text "LockedReason"
    t.integer "NotActive", limit: 2, default: 0, null: false
    t.decimal "NotActiveDate", precision: 12, default: "0"
    t.text "NotActiveReason"
    t.integer "Coordinator", limit: 2
    t.integer "WorkingWith"
    t.string "Surname", limit: 50, null: false
    t.string "GivenName", limit: 100
    t.string "UserID", limit: 50, null: false, collation: "latin1_bin"
    t.string "Password", limit: 50, default: ""
    t.string "NewPassword", limit: 50, default: ""
    t.string "RealPassword", limit: 50, default: ""
    t.string "ScanAccessRole", limit: 20
    t.string "EmailID", limit: 50, null: false
    t.string "Country", limit: 20
    t.string "PublicKey", limit: 50
    t.integer "Active", limit: 2, null: false
    t.string "Challenge", limit: 6
    t.decimal "ChallengeGenerated", precision: 12, comment: "date challenge last SENT TO USER"
    t.decimal "ChallengeConfirmed", precision: 12
    t.integer "FicheReader", limit: 2
    t.integer "LookingForSyndicate", limit: 2
    t.decimal "UnixTimeEntered", precision: 12
    t.string "CoordinatorName", limit: 50
    t.integer "CoordAccess", limit: 1, default: 0
    t.integer "PrivacyKey", limit: 2
    t.integer "AcceptCorrections", limit: 2
    t.integer "Contactable", limit: 1, default: 1
    t.text "CorrectionConfig"
    t.text "CorrectionNotification"
    t.integer "TotalEntries"
    t.integer "UserType", limit: 2, default: 0
    t.integer "Role", default: 1
    t.text "Notes"
    t.index ["EmailID"], name: "EmailID"
    t.index ["UserID"], name: "UserID", unique: true
  end

  create_table "submittersyndicates", id: false, force: :cascade, options: "ENGINE=MyISAM DEFAULT CHARSET=latin1" do |t|
    t.string "UserID", limit: 50, null: false, collation: "latin1_bin"
    t.string "SyndicateName", limit: 50, null: false
    t.index ["UserID"], name: "UserID"
  end

  create_table "transcriptionpage", id: false, force: :cascade, options: "ENGINE=MyISAM DEFAULT CHARSET=latin1" do |t|
    t.string "Page", limit: 20
    t.integer "FileNumber", limit: 3, null: false, unsigned: true
    t.integer "StartLine", limit: 3, null: false, unsigned: true
    t.integer "Count", limit: 3, unsigned: true
    t.string "FirstName", limit: 50
    t.string "FirstGivenname", limit: 100
    t.string "LastName", limit: 50
    t.integer "Year", limit: 2, null: false
    t.integer "EntryQuarter", limit: 1, null: false
    t.integer "RecordTypeID", limit: 1, null: false
    t.string "SourceType", limit: 2
    t.string "SourceID", limit: 200
    t.string "TransDate", limit: 50
    t.integer "FromFiche", limit: 2, null: false
    t.string "FicheRange", limit: 50
    t.string "FicheNumber", limit: 50, default: ""
    t.index ["EntryQuarter"], name: "EntryQuarter"
    t.index ["FileNumber"], name: "FileNumber"
    t.index ["Year", "EntryQuarter", "RecordTypeID"], name: "Year"
    t.index ["Year"], name: "Year_2"
  end

  create_table "uniqueforenames", primary_key: "NameID", id: :integer, default: nil, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci" do |t|
    t.string "Name", limit: 100
    t.string "LcName", limit: 100
    t.integer "count"
    t.index ["Name"], name: "Names"
  end

  create_table "uniquesurnames", primary_key: "NameID", id: :integer, default: nil, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci" do |t|
    t.string "Name", limit: 100
    t.string "LcName", limit: 100
    t.integer "count"
    t.index ["Name"], name: "Names"
  end

end
