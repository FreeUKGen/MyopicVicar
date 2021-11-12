require 'text'
module SearchQueriesHelper

  def results_search_form_link
    link_to "New Search", new_search_query_path, class: "btn  btn--small "
  end

  def results_revise_search_form_link
    link_to "Revise Search", new_search_query_path(:search_id => @search_query), :class => "btn  btn--small"
  end

  def results_about_search_link
    link_to("About This Query", about_search_query_path(@search_query, :page_number => @page_number), :class => "btn  btn--small")
  end

  def results_broaden_search_link
    if @search_query.can_be_broadened?
      link_to "Broaden Search", broaden_search_query_path(:search_id => @search_query) , :class => "btn  btn--small"
    end
  end
  def results_narrow_search_link
    if @search_query.can_be_narrowed?
      link_to "Narrow Search", narrow_search_query_path(:search_id => @search_query), :class => "btn  btn--small"
    end
  end

  def results_printable_link
    if device_type == :desktop || device_type == :tablet
      link_to "Printable Format", show_print_version_search_query_path , :class => "btn  btn--small"
    end
  end

  def fuzzy(verbatim)
    Text::Soundex.soundex(verbatim)
  end

  def birth_place(search_record)
    birth_place = ''
    if search_record.freecen_csv_entry_id.present?
      birth_place = search_record.birth_place
    else
      individual = FreecenIndividual.find_by(_id: search_record.freecen_individual_id) if search_record.freecen_individual_id.present?
      birth_place = individual.birth_place if individual.present?
    end
    birth_place
  end

  def format_freecen_birth_year(search_date, record_type)
    search_year = search_date.gsub(/\D.*/,'')
    if search_year == record_type
      search_year
    else
      if record_type == RecordType::CENSUS_1841 && search_year > "1826"
        "#{search_year.to_i - 3}"
      else
        "#{search_year.to_i - 1}"
      end
    end
  end

  def format_start_date(year)
    "January 1, "+DateParser::start_search_date(year)
  end

  def format_end_date(year)
    Date.parse(DateParser::end_search_date(year)).strftime("%B %d, %Y")
  end

  #def format_for_line_breaks(names)
  #raw(names.map{ |name| name.gsub(' ', '&nbsp;')}.join(' '))
  #end

  def format_location(search_record)
    case MyopicVicar::Application.config.template_set
    when 'freereg'
      location = format_freereg_location(search_record)
    when 'freecen'
      location = format_free_location(search_record)
    when 'freebmd'
      location = format_free_location(search_record)
    end
    location
  end

  def format_freereg_location(search_record)
    result = false
    entry = search_record.freereg1_csv_entry
    file = entry.freereg1_csv_file if entry.present?
    result, place, church, register = file.location_from_file if file.present?
    if file.present? && result
      location = "#{place.place_name} : #{church.church_name} : #{RegisterType.display_name(register.register_type)}"
    else
      location =  'Unknown location'
      logger.warn "#{appname_upcase}::SEARCH::RECORD ID is  #{search_record.id}"
    end
    location
  end

  def format_free_location(search_record)
    if search_record[:location_name].present?
      search_record[:location_name]
    elsif search_record[:location_names].present?
      format_for_line_breaks(search_record[:location_names])
    else
      ""
    end
  end

  def cen_location(search_record)
    if search_record.freecen_csv_entry_id.present?
      entry = FreecenCsvEntry.find_by(_id: search_record.freecen_csv_entry_id)
      if entry.present?
        district = entry.where_census_taken.presence || entry.freecen_csv_file.freecen2_piece.district_name
      else
        district = Freecen2District.find_by(_id: search_record.freecen2_district_id)
        district = district.present? ? district.name : search_record[:location_names][0]
      end
    else
      district = search_record[:location_names][0]
    end
    district
  end

  def county(search_record)
    chapman = search_record[:chapman_code]
    if chapman.present?
      county = ChapmanCode.has_key(chapman)
    else
      place = Place.id(search_record[:place_id].to_s).first
      place.present? ? county = place.county : county = ""
    end
    county
  end

  def transcript_date(search_record)
    transcript_dates = search_record.transcript_dates
    transcript_dates.each do |transcript_date|
      return transcript_date if transcript_date.present?
    end
    return ""
  end

  def format_for_line_breaks (names)
    place = ' '
    name_parts = names[0].split(') ')
    case
    when name_parts.length == 1
      (place, church) = names[0].split(' (')
    when name_parts.length == 2
      place = name_parts[0] + ")"
      name_parts[1][0] = ""
      church = name_parts[1]
    else
    end
    if church.present?
      church = church[0..-2]
    else
      church = ' '
    end
    if names[1]
      register_type = names[1].gsub('[', '').gsub(']', '')
      loc = [place, church, register_type].join(' : ')
    else
      loc = place
    end

    return loc
  end

  def place_name_from_id(ids)
    place_names = []
    ids.each do |id|
      place = Place.id(id).first
      place_name = place.present? ? place.place_name : place_name = ''
      place_names << place_name
    end
    place_names
  end

  def show_contents_link
    if MyopicVicar::Application.config.template_set == 'freereg'
      contents_link =  link_to "Transcriptions" , "/freereg_contents/new", :title => "By county, place and church"
    elsif MyopicVicar::Application.config.template_set == 'freecen'
      contents_link = link_to "Database Coverage" , freecen_coverage_path, :title => "Database Coverage"
    elsif MyopicVicar::Application.config.template_set == 'freebmd'
      contents_link = link_to "Database Coverage" , freecen_coverage_path, :title => "Database Coverage"
    end
  end

  def set_value field_value=nil
    return field_value
  end

  def set_checkbox_checked_value field_value:, value: nil
    return field_value.include?value
  end

  def bmd_record_type_name search_record_type
    search_record_type.map do |rec_type|
      next if rec_type == '0'
      RecordType::display_name(rec_type.to_i)
    end
  end

  def bmd_search_criteria search_query
    display_map = {}
    display_map["First Name"] = search_query.first_name.present? ? search_query.first_name.upcase : "Not Specified" 
    display_map["Last Name"] = search_query.last_name.present? ? search_query.last_name.upcase : "Not Specified"
    display_map["First Name Exact Match?"] = search_query.first_name_exact_match ? 'Yes' : 'No'
    display_map["Phonetic Surnames"] = search_query.fuzzy ? 'Yes' : 'No'
    display_map["Search Start Date"] = "#{QuarterDetails.quarters.key(search_query.start_quarter).upcase} #{search_query.start_year}"
    display_map["Search End Date"] = "#{QuarterDetails.quarters.key(search_query.end_quarter).upcase} #{search_query.end_year}"
    if search_query.bmd_record_type.present?
      display_map["Record Type"] = bmd_record_type_name(search_query.bmd_record_type).compact.to_sentence
    end
    display_map["Spouse First Name"] = search_query.spouse_first_name if search_query.spouse_first_name
    display_map["Identifiable Spouses Only"] = 'Yes' if  search_query.identifiable_spouse_only
    display_map["Spouse Surname"] = search_query.spouses_mother_surname if search_query.spouses_mother_surname
    display_map["Mother Surname"] = search_query.mother_last_name if search_query.mother_last_name.present?
    display_map["Volume"] = search_query.volume if search_query.volume
    display_map["Page"] = search_query.page if search_query.page
    counties = search_query.chapman_codes.map{|code| ChapmanCode::name_from_code(code)}.join(" or ")
    display_map["Counties"] = counties if search_query.chapman_codes.size >= 1
    display_map["Districts"] = search_query.get_district_name if search_query.districts.compact.size >= 1
    display_map["Age At Death"] = "#{search_query.age_at_death}#{search_query.dob_at_death}" if search_query.age_at_death.present? || search_query.dob_at_death.present?
    display_map["Age At Death Range"] = "#{search_query.min_age_at_death}-#{search_query.max_age_at_death}" if search_query.min_age_at_death.present?
    display_map["Date of Birth Range"] = "(#{search_query.min_dob_at_death}) - (#{search_query.max_dob_at_death})" if search_query.max_dob_at_death.present?
    display_map["Match Recorded Ages/Date of Birth"] = 'Yes' if  search_query.match_recorded_ages_or_dates
    display_map["Partial search on"] = search_query.wildcard_field if search_query.wildcard_field.present?
    display_map["Partial search type"] = search_query.wildcard_option if search_query.wildcard_option.present?
    display_map
  end
end
