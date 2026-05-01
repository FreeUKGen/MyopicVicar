require 'set'
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
    # Memoized per request; viewed_records is read once; Set gives O(1) lookup per id candidate.
    @viewed_search_record_id_set ||= Set.new(
      (search_query&.search_result&.viewed_records || []).map(&:to_s)
    )
    return '' if @viewed_search_record_id_set.empty?

    id_strings =
      if search_record.is_a?(SearchRecord)
        [search_record.id, search_record.freereg1_csv_entry_id].compact.map(&:to_s)
      else
        rid = search_record[:_id] || search_record['_id']
        eid = search_record[:freereg1_csv_entry_id] || search_record['freereg1_csv_entry_id']
        [rid, eid].compact.map(&:to_s)
      end

    if id_strings.any? { |s| @viewed_search_record_id_set.include?(s) }
      '(Seen)'
    else
      ''
    end
  end

  def entitle(record)
    record = record.present? ? record.titleize : record
  end

  # Citation / bookmark URL only: for FreeREG use the line id (stable if SearchRecord is rebuilt). Else SearchRecord id.
  def search_record_link(record)
    id_for_url =
      if record.is_a?(SearchRecord) && record.freereg1_csv_entry_id.present?
        record.freereg1_csv_entry_id.to_s
      elsif record.is_a?(SearchRecord)
        record.id.to_s
      else
        record.to_s
      end
    Rails.application.config.website + '/search_records/' + id_for_url
  end

end
