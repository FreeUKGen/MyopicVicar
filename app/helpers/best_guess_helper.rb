module BestGuessHelper
  require 'uri'

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
      header = "Mother's Maiden Name"
    when "marriage"
      header = "Spouse Surname"
    end
    header
  end

  def calculate_quarter number
    (number-1)%4 + 1
  end

  def format_quarter quarter
    if quarter <  Constant::EVENT_QUARTER_TO_YEAR
      date = "#{(format_quarter_name quarter).camelize} #{formatted_year quarter}"
    else
      #date = formatted_year quarter
    end
    date
  end

  def format_quarter_year quarter
    if quarter <  Constant::EVENT_QUARTER_TO_YEAR
      date = "#{(format_quarter_name quarter).camelize} #{formatted_year quarter}"
    else
      date = formatted_year quarter
    end
    date
  end

  def format_quarter_name quarter
    QuarterDetails.quarter_hash[calculate_quarter(quarter).to_s]
  end

  def brief_quarter_name quarter
    QuarterDetails.quarter_abbreviated_hash[quarter]
  end
  def formatted_month quarter
    QuarterDetails.quarters.key(calculate_quarter quarter)
  end

  def formatted_year quarter
    from_quarter_to_year quarter
  end

  def format_registered registered_date, quarter
    if (registered_date.length == 4)
      registered_date.insert(2, '.')
    end
    registered = registered_date.split('.')
    year = formatted_year(quarter).to_s
    value = "#{QuarterDetails.month_hash[registered[0]]} #{year[0..1]}#{registered[1]}"
    value
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
    image_server = Rails.application.config.image_server
    [year, event, quarter, image_server]
  end

  def scan_link_url entry, hash
    @year, @event, @quarter, @image_server = scan_url_constants(entry)
    series = hash[:series]&.present? ? hash[:series] : ''
    range = hash[:range]&.present? ? hash[:range] : ''
    file = hash[:file]&.present? ? hash[:file] : ''
    p = "#{series}/#{range}/#{file}"
    event = @event.downcase[0]
    v = SecurityHash.make_security_hash
    detected_action = get_action_from_filename(file)
    file = ensure_file_extension(file)
    params_one = {y: @year,q: @quarter,e: event,l: 'A-Z', p: p, v: v,actiontype: detected_action}
    params_two = {y: @year,e: event,l: 'A-Z', p: p, v: v,actiontype: detected_action}
    query_string_one = URI.encode_www_form(params_one)
    query_string_two = URI.encode_www_form(params_two)
    if entry.QuarterNumber <  Constant::EVENT_QUARTER_TO_YEAR
      image_path = "#{@image_server}?#{query_string_one}"
    else
      image_path = "#{@image_server}?#{query_string_two}"
    end
    image_path
  end

  def initial_to_event_type event_type
    case event_type
    when "B"
      result = "Births"
    when "M"
      result = "Marriages"
    when "D"
      result = "Deaths"
    else
      result = "Unknown Event Type #{event_type}"
    result
    end
  end

  def value_or_no_data(field_value)
    unless field_value.blank?
      field_value
    else "No data"
    end
  end

  def render_scan_rows(scan_links, acc_scans, acc_mul_scans, current_record)
    content = ""

    # Process scan_links
    scan_links&.each do |scan|
      content += render_scan_row({series: scan.SeriesRangeFileName}, current_record)
    end

    # Process acc_scans
    acc_scans&.each do |scan|
      series = scan.SeriesID
      range = scan.Range.present? ? scan.range.Range : ""
      file = scan.Filename
      content += render_scan_row({series:series, range: range, file: file}, current_record)
    end

    # Process acc_mul_scans
    acc_mul_scans&.each do |scan|
      series = scan.SeriesID
      range = scan.Range.present? ? scan.Range : ""
      current_record.multi_image_filenames.each do |filename|
        content += render_scan_row({series:series, range: range, file: file}, current_record)
      end
    end

    content.html_safe
  end

private

  def render_scan_row(series_path, current_record)
    image_url = BestGuess.build_image_server_request(scan_link_url(current_record, series_path))
    link_to_text = "#{series_path[:series]}/#{series_path[:range]}/#{series_path[:file]}"
    content_tag(:li, link_to(link_to_text, image_url, target: "_blank", class: "scan-link"))
  end

  def get_action_from_filename(filename)
    return 'Original' if filename.blank?

    extension = File.extname(filename).downcase

    case extension
    when '.jpg', '.jpeg'
      'JPG'
    when '.gif'
      'GIF'
    when '.tif', '.tiff'
      'TIFF'
    when '.pdf'
      'PDF'
    else
      'Original'
    end
  end

  def ensure_file_extension(file)
    return file if file.blank?

    # Add .jpg extension if missing or incomplete
    if !file.match?(/\.(jpg|jpeg|gif|tif|tiff)$/i)
      file + '.jpg'
    else
      file
    end
  end
end