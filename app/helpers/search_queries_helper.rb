require 'text'
module SearchQueriesHelper
  def fuzzy(verbatim)
    Text::Soundex.soundex(verbatim)
  end

  def format_start_date(year)
    "January 1, "+DateParser::start_search_date(year)
  end

  def format_end_date(year)
    Date.parse(DateParser::end_search_date(year)).strftime("%B %d, %Y")
  end

end
