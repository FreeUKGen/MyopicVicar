require 'text'
module SearchQueriesHelper
  def fuzzy(verbatim)
    Text::Soundex.soundex(verbatim)
  end

  def format_freecen_birth_year(search_date, record_type)
    search_year = search_date.gsub(/\D.*/,'')
    if search_year == record_type
      search_year
    else
      if record_type == RecordType::CENSUS_1841 && search_year > "1826"
        "#{search_year.to_i - 3} - #{search_year.to_i + 2}"              
      else
        "#{search_year.to_i - 1} - #{search_year}"      
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
    if search_record[:location_name].present?
      search_record[:location_name]
    elsif
      search_record[:location_names].present?
      format_for_line_breaks(search_record[:location_names])
    else
      ""
    end
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

end
