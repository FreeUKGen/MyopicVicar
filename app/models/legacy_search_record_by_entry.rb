# frozen_string_literal: true

# Inverted legacy map: one document per Freereg1CsvEntry line, listing all retired SearchRecord _ids
# that should redirect to this line. Complements LegacySearchRecordMapping (flat old_id -> target).
# Lookup: LegacySearchRecordByEntry.where(legacy_search_record_ids: url_id).first
class LegacySearchRecordByEntry
  include Mongoid::Document

  field :freereg1_csv_entry_id, type: String
  field :legacy_search_record_ids, type: Array, default: -> { [] }

  index({ freereg1_csv_entry_id: 1 }, { unique: true })
  index({ legacy_search_record_ids: 1 })

  # Returns the document whose legacy_search_record_ids contains this id, or nil.
  def self.find_by_legacy_search_record_id(legacy_id)
    id_s = legacy_id.to_s.strip
    return nil if id_s.blank?

    where(legacy_search_record_ids: id_s).first
  end

  # Upsert one row per entry; add old SearchRecord id to the set (idempotent).
  def self.add_legacy_id!(freereg1_csv_entry_id:, legacy_search_record_id:)
    entry_s = freereg1_csv_entry_id.to_s.strip
    old_s = legacy_search_record_id.to_s.strip
    return nil if entry_s.blank? || old_s.blank?
    return nil if old_s == entry_s

    doc = find_or_initialize_by(freereg1_csv_entry_id: entry_s)
    ids = (doc.legacy_search_record_ids || []).map(&:to_s)
    return doc if ids.include?(old_s)

    ids << old_s
    doc.legacy_search_record_ids = ids
    doc.save(validate: false)
    doc
  rescue StandardError => e
    app = MyopicVicar::Application.config.freexxx_display_name.to_s.upcase
    Rails.logger.warn("#{app}::LEGACY_SEARCH_BY_ENTRY add failed entry=#{entry_s} old=#{old_s}: #{e.class}: #{e.message}")
    nil
  end

  # Resolve Freereg1CsvEntry id from a flat LegacySearchRecordMapping row (for backfill / CSV).
  def self.freereg_entry_id_from_flat_mapping(mapping)
    return mapping.freereg1_csv_entry_id.to_s.strip if mapping.freereg1_csv_entry_id.present?
    return '' if mapping.new_id.blank?

    sr = SearchRecord.find_for_show_param(mapping.new_id)
    sr&.freereg1_csv_entry_id&.to_s&.strip || ''
  end
end
