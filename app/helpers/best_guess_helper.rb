module BestGuessHelper
  def seen(search_query, search_record)
    search_results = search_query.search_result
    viewed_records = search_results.viewed_records
    field = ''
    #raise viewed_records.inspect
    if viewed_records.present?
      field = '(Seen)' if viewed_records.include?("#{search_record[:RecordNumber]}")
    end
    field
  end

  def mother_or_spouse_surname(record_type)
    case record_type.downcase
    when "birth"
      header = "Mothers Surname"
    when "marriage"
      header = "Spouse Surname"
    end
    header
  end

  def calculate_quarter number
    (number-1)%4 + 1
  end

  def format_quarter quarter
    "#{(formatted_month quarter).upcase} #{formatted_year quarter}"
  end

  def formatted_month quarter
    QuarterDetails.quarters.key(calculate_quarter quarter)
  end

  def formatted_year quarter
    from_quarter_to_year quarter
  end

  def from_quarter_to_year quarter
    (quarter-1)/4 + 1837
  end

  def record_type_name entry
    RecordType::display_name(entry.RecordTypeID)
  end

  def format_record_type_for_scan_url entry
    record_type_name(entry).capitalize
  end

  def scan_url_constants entry
    year = from_quarter_to_year(entry.QuarterNumber)
    event = "#{format_record_type_for_scan_url(entry)}s"
    quarter = QuarterDetails.quarters.key(calculate_quarter(entry.QuarterNumber)).capitalize
    image_server = "https://images.freebmd.org.uk/SUG"
    [year, event, quarter, image_server]
  end

  def scan_link_url entry
    @year, @event, @quarter, @image_server = scan_url_constants(entry)
    image_path = "#{@image_server}/#{@year}/#{@event}/#{@quarter}/"
    image_path
  end
end