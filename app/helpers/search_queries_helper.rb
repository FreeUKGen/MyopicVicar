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
  
  def format_for_line_breaks(names)
    raw(names.map{ |name| name.gsub(' ', '&nbsp;')}.join(' '))
  end

  def format_location(search_record)
    if search_record.respond_to? :location_name
      search_record.location_name
    elsif
      search_record.respond_to? :location_names
      format_for_line_breaks(search_record.location_names)
    else
      ""
    end
  end

end
