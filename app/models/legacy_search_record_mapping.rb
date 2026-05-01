# frozen_string_literal: true

# Stores mapping from old SearchRecord _id (before rebuild or delete) to the current record.
# Populated manually (CSV rake) and automatically when a FreeREG SearchRecord is destroyed
# (see SearchRecord before_destroy). Redirect target: prefer freereg1_csv_entry_id; fall back to new_id
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