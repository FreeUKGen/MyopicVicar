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
    # Cache the viewed_records lookup to avoid repeated access to search_result
    @viewed_records_cache ||= begin
      search_results = search_query.search_result
      search_results.viewed_records || []
    end
    
    field = ''
    if @viewed_records_cache.present?
      field = '(Seen)' if @viewed_records_cache.include?("#{search_record[:_id]}")
    end
    field
  end

  def entitle(record)
    record = record.present? ? record.titleize : record
  end

  def search_record_link(record)
    field = Rails.application.config.website + '/search_records/' + record
    field
  end

end
