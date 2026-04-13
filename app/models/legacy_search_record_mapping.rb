# frozen_string_literal: true

# Stores mapping from old SearchRecord _id (before rebuild) to new _id.
# Used to redirect old citation/record URLs to the current record.
class LegacySearchRecordMapping
    include Mongoid::Document

    field :old_id, type: String
    field :new_id, type: String

    index({ old_id: 1 }, { unique: true })
    index({ new_id: 1 })
end