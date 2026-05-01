# frozen_string_literal: true

# Flat mapping: old SearchRecord _id -> new_id / freereg1_csv_entry_id.
# Populated via CSV rake (update_lost_search_record_ids) and SearchRecord.write_legacy_freereg_mapping!.
# Redirect resolution also tries LegacySearchRecordByEntry (inverted: many legacy ids per entry).
# Redirect target: prefer freereg1_csv_entry_id; fall back to new_id
# (SearchRecord id or entry id — see SearchRecord.find_for_show_param).
class LegacySearchRecordMapping
  include Mongoid::Document

  field :old_id, type: String
  field :new_id, type: String
  field :freereg1_csv_entry_id, type: String

  index({ old_id: 1 }, { unique: true })
  index({ new_id: 1 })
  index({ freereg1_csv_entry_id: 1 })
end