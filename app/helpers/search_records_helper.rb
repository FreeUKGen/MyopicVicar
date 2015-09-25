module SearchRecordsHelper
  def record_type(entry)
    if @entry.freereg1_csv_file.present?
      field = RecordType::display_name(@entry.freereg1_csv_file.record_type)
    else
      field = entry.record_type
      logger.warn("ENTRY ERROR #{entry.id} #{entry.line_id} #{entry.place} #{entry.church_name} #{entry.register_type} #{entry.freereg1_csv_file_id} is missing}")
    end
    field
  end
end
