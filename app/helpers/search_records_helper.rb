module SearchRecordsHelper

  def dwelling_offset_message(offset)
    msg = ''
    if 0 == offset
      return msg
    end
    bef_aft = 'after'
    if offset < 0
      bef_aft = 'before'
      offset = 0 - offset
    end
    suffix = 'th'
    if (3 == offset % 10) && (13 != offset % 100)
      suffix = 'rd'
    elsif (2 == offset % 10) && (12 != offset % 100)
      suffix = 'nd'
    elsif (1 == offset % 10) && (11 != offset % 100)
      suffix = 'st'
    end
    msg = '(' + offset.to_s + suffix + ' dwelling ' + bef_aft + ' the current search result)'
    msg
  end

  def record_type(entry)
    if @entry.freereg1_csv_file.present?
      field = RecordType::display_name(@entry.freereg1_csv_file.record_type)
    else
      field = RecordType::display_name(entry.record_type)
      logger.warn("ENTRY ERROR #{entry.id} #{entry.line_id} #{entry.freereg1_csv_file_id} is missing}")
    end
    field
  end
end
