module SearchRecordsHelper

  def dwelling_offset_message(offset)
    msg = ''
    return msg if offset.blank? || offset.to_i == 0

    bef_aft = 'after'
    if offset < 0
      bef_aft = 'before'
      offset = 0 - offset
    end
    msg = '(' + offset.ordinalize + ' dwelling ' + bef_aft + ' the current search result)'
    msg
  end

  def record_type(entry)
    if @entry.freereg1_csv_file.present?
      field = RecordType::display_name(@entry.freereg1_csv_file.record_type)
    else
      field = RecordType::display_name(entry.record_type)

      logger.warn("#{appname_upcase}::ENTRY ERROR #{entry.id} #{entry.line_id} #{entry.freereg1_csv_file_id} is missing}")
    end
    field
  end

  def viewed(search_query, search_record)
    search_results = search_query.search_result
    viewed_records = search_results.viewed_records
    field = ''
    if viewed_records.present?
      field = '(Seen)' if viewed_records.include?("#{search_record[:_id]}")
    end
    field
  end

  def entitle(record)
    record = record.present? ? record.titleize : record
  end

  # Citation / bibliography URL only: FreeREG uses stable freereg1_csv_entry id. Elsewhere use SearchRecord id.
  def search_record_link(record)
    base = Rails.application.config.website
    if appname_downcase == 'freereg'
      entry_id =
        if record.is_a?(SearchRecord) && record.freereg1_csv_entry_id.present?
          record.freereg1_csv_entry_id.to_s
        elsif record.is_a?(Hash)
          record[:freereg1_csv_entry_id].presence || record['freereg1_csv_entry_id'].presence
        end
      return base + freereg1_csv_entry_path(entry_id) if entry_id.present?
    end

    id_part = record.is_a?(Hash) ? (record[:_id] || record['_id'] || record[:id] || record['id']) : record
    base + '/search_records/' + id_part.to_s
  end

end
