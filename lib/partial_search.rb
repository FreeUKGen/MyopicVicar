class PartialSearch
	def initialize(field=nil, partial = nil, search_id)
    @field = field
    @partial = partial
    @search_id = search_id
  end

  def partial_search_query
    if general_partials.include?@partial
      query = general_partial_query
    elsif @partial == "Exact Match"
      query = exact_match_wildcard_query
    else
    end
    query.present? ? query : {}
  end
  

  private

  STARTS_WITH = "Starts with"
  CONTAINS = "Contains"
  ENDS_WITH = "Ends with"
  EXACT_MATCH = "Exact Match"

  def get_search
  	SearchQuery.find_by(id: @search_id)
  end

  def get_attribute_name
    Constant::NAME_FIELD[@field]
  end

  def partial_field_value_hash
    {
      Constant::NAME[0] => get_search.first_name,
      Constant::NAME[1] => get_search.first_name,
      Constant::NAME[2] => get_search.last_name,
      Constant::NAME[3] => get_search.mother_last_name,
    }
  end

  def partial_search_attribute
  	"BestGuess.#{get_attribute_name} like ?"
  end

  def get_value
  	partial_field_value_hash[@field]
  end

  def partial_search_attribute_value
  	percentage_wildcard_usage_conditions(get_value)
  end

  def percentage_wildcard_usage_conditions str
  	case @partial
    when "Starts with"
    	v = "#{str}%"
    when "Contains"
    	v = "%#{str}%"
    when "Ends with"
    	v = "%#{str}"
    end
    v
  end

  def general_partials
  	[STARTS_WITH, CONTAINS, ENDS_WITH]
  end

  def general_partial_query
  	field, value = partial_search_attribute, partial_search_attribute_value
    {field => value}
  end

  def exact_match_partial_query
    field, value = "BestGuess.#{get_attribute_name} = ?", get_value
    {field => value}
  end

end