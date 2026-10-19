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
    # Memoized per request; avoids re-reading viewed_records for every result row.
    @viewed_search_record_id_set ||= Set.new(
      (search_query&.search_result&.viewed_records || []).map(&:to_s)
    )
    return '' if @viewed_search_record_id_set.empty?

    rid = search_record[:_id] || search_record['_id']
    if @viewed_search_record_id_set.include?(rid.to_s)
      '(Seen)'
    else
      ''
    end
  end

  def entitle(record)
    record = record.present? ? record.titleize : record
  end

  def marriage_date_for_citation(entry)
    entry['marriage_date'].presence || entry['contract_date']
  end

  def search_record_link(record)
    field = Rails.application.config.website + '/search_records/' + record
    field
  end

end
