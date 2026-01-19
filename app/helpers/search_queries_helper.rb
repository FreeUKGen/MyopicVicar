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

  def search_birth_place(search_record)
    birth = ''
    verbatim_birth_place = ''
    if search_record.freecen_csv_entry_id.present?
      entry = search_record.freecen_csv_entry
    else
      entry = search_record.freecen_individual
    end
    birth = entry.birth_place if entry.present?
    verbatim_birth_place = entry.verbatim_birth_place if entry.present?
    birth = birth + ' (or ' + verbatim_birth_place + ')' if birth.present? && verbatim_birth_place.present? && birth != verbatim_birth_place
    birth = verbatim_birth_place if birth.blank?
    birth
  end


  def search_birth_county(search_record)
    birth_county_name = ''
    verbatim_birth_county_name = ''
    if search_record.freecen_csv_entry_id.present?
      entry = search_record.freecen_csv_entry
    else
      entry = search_record.freecen_individual
    end
    birth_county_name = ChapmanCode.name_from_code(entry.birth_county) if entry.present?
    verbatim_birth_county_name = ChapmanCode.name_from_code(entry.verbatim_birth_county) if entry.present?
    birth_county_name = birth_county_name + ' (or ' + verbatim_birth_county_name + ')' if birth_county_name.present? &&
      verbatim_birth_county_name.present? && birth_county_name != verbatim_birth_county_name
    birth_county_name = verbatim_birth_county_name if birth_county_name.blank?
    birth_county_name
  end

  def format_freecen_birth_year(search_date, record_type)
    search_date_year = search_date.gsub(/\D.*/, '')
    # trap where age was recorded as 999 assumes indiv has to be < 200 yrs old
    search_date_year.to_i < record_type.to_i - 200 ? 'unk' : search_date_year
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
    # Use cached location if available (from preloading)
    if @location_cache && @location_cache[search_record.id.to_s]
      return @location_cache[search_record.id.to_s]
    end
    
    # Fallback to original method if cache not available
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
      if Rails.application.config.freecen2_place_cache
        place = search_record.freecen2_place
        district = place.place_name if place.present?
      else
        vld = search_record.freecen1_vld_file
        place = search_record.place
        district = place.place_name if place.present?
        if vld.present? && place.blank?
          piece = vld.freecen_piece
          district = piece.district_name if piece.present?
        end
      end
    end
    district
  end

  def county(search_record)
    # Use cached county if available (from preloading)
    if @county_cache && @county_cache[search_record.id.to_s]
      return @county_cache[search_record.id.to_s]
    end
    
    # Fallback to original method if cache not available
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
      contents_link = link_to "Database Coverage" , freebmd_coverage_path, :title => "Database Coverage"
    end
  end
end
